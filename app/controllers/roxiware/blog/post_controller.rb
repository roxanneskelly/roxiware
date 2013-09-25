module Roxiware
   module Blog
      class PostController < ApplicationController
         include Roxiware::ApplicationControllerHelper

         application_name "blog"

         load_and_authorize_resource :only=>[:show, :update, :edit, :destroy], :class=>"Roxiware::Blog::Post"

	 before_filter do
	     redirect_to("/") unless @enable_blog
	 end

	 before_filter do
	   @role = "guest"
	   @role = current_user.role unless current_user.nil?
	   @person_id = (current_user && current_user.person)?current_user.person.id : -1
	 end

         def redirect_by_title
	   conditions = {}
	   if params.has_key?(:year)
	      start_date = DateTime.new(params[:year].to_i, 
	                            (params[:month] || 1).to_i, 
                                    (params[:day] || 1).to_i,
				    0, 0, 0)
	      end_date = DateTime.new(params[:year].to_i, 
	                          (params[:month] || -1).to_i, 
				  (params[:day] || -1).to_i,
				  -1, -1, -1)
              conditions[:post_date] =start_date..end_date
              posts = Roxiware::Blog::Post.visible(current_user).where(conditions)
	      post = nil
	      posts.each do |current_post|
	        if current_post.post_title.to_seo == params[:title]
		   post = current_post
		   break
		end
	      end
              raise ActiveRecord::RecordNotFound if post.nil?
              respond_to do |format|
	        format.html { redirect_to post.post_link }
	      end
           end
         end

	 def index_by_date
	   @enable_blog_edit = true
	   authorize! :read, Roxiware::Blog::Post
	   @page = (params[:page] || 1).to_i
	   @blog_class = params[:blog_class] || "blog"
	   conditions = {:blog_class=>@blog_class}
	   if params[:format] == "rss"
              @num_posts = [(params[:max] || @blog_posts_per_feed).to_i, @max_blog_posts_per_feed].min
	   else
              @num_posts = [(params[:max] || @blog_posts_per_page).to_i, @max_blog_posts_per_page].min
	   end

	   if params.has_key?(:year)
	      start_date = DateTime.new(params[:year].to_i, 
	                            (params[:month] || 1).to_i, 
                                    (params[:day] || 1).to_i,
				    0, 0, 0)
	      end_date = DateTime.new(params[:year].to_i, 
	                          (params[:month] || -1).to_i, 
				  (params[:day] || -1).to_i,
				  -1, -1, -1)
              conditions[:post_date] =start_date..end_date
	   end

	   if params.has_key?(:category)
              conditions[:terms] = {:term_taxonomy_id=>Roxiware::Terms::TermTaxonomy.taxonomy_id(Roxiware::Terms::TermTaxonomy::CATEGORY_NAME), :seo_index=>params[:category]}
	   end
	   if params.has_key?(:tag)
              conditions[:terms] = {:term_taxonomy_id=>Roxiware::Terms::TermTaxonomy.taxonomy_id(Roxiware::Terms::TermTaxonomy::TAG_NAME), :seo_index=>params[:tag]}
	   end

	   if conditions.has_key?(:terms)
	     @posts = Roxiware::Blog::Post.joins(:terms).visible(current_user).includes(:term_relationships, :terms).where(conditions).order("post_date DESC")
	   else 
	     @posts = Roxiware::Blog::Post.visible(current_user).includes(:term_relationships, :terms).where(conditions).order("post_date DESC")
	   end

	   @num_posts_total = @posts.count
           @posts = @posts.limit(@num_posts+1).offset(@num_posts*(@page-1))
	   @num_pages = (@num_posts_total.to_f/@num_posts.to_f).ceil.to_i
           @link_params = {}
	   @link_params[:max] = params[:max] if params[:max].present?
           if (@posts.length == @num_posts+1)
	      @posts.pop
	      @next_page_link = url_for({:page=>@page+1}.merge @link_params)
	   end
	   if(@page > 1)
	      @prev_page_link = url_for({:page=>@page-1}.merge @link_params)
	   end

	   respond_to do |format|
	     format.html do 
               @page_title = @title 
	       @posts.each do |post| 
	         @meta_keywords = @meta_keywords + ", " + post.post_title
	       end 
	        render :action=>"index"
             end
	     format.json do
                clean_posts = []
                @posts.each do |post| 
                  clean_posts << post.ajax_attrs(@role)
	        end 
                render :json => clean_posts 
	     end
             format.rss { render :layout => false, :action=>"index", :content_type=>"application/rss+xml" }
	   end
	 end

	 # GET /posts/1
	 # GET /posts/1.json
	 def show_by_title
	   @enable_blog_edit = true
	   @post = Roxiware::Blog::Post.where(:guid=>request.path).first
	   @page_images = [@post.post_image]
	   @blog_class = params[:blog_class] || "blog"
	   raise ActiveRecord::RecordNotFound if @post.nil?
	   authorize! :read, @post

	   @prev_post_link = nil
	   @next_post_link = nil
           calendar_posts_index = Roxiware::Blog::Post.visible(current_user).where(:blog_class=>@blog_class).order("post_date DESC").select("id, post_title, post_date, post_link, post_status")
	   calendar_posts_index.each do |post|
	      if post.id != @post.id
	        if(post.post_date > @post.post_date)
	          @next_post_link = post.post_link
	        elsif post.post_date < @post.post_date
	          @prev_post_link = post.post_link
		  break
	        end
              end
	   end

	   conditions = {}
	   person_id = ((current_user && current_user.person)?current_user.person.id : -1)

           comments = @post.comments.visible(current_user).order("comment_date DESC")

           # create comment hierarchy
	   @comments = {}
           comments.each do |comment|
	       @comments[comment.parent_id] ||= {:children=>[]}
	       @comments[comment.id] ||= {:children=>[]}
	       @comments[comment.parent_id][:children] << comment.id
	       @comments[comment.id][:comment] = comment
	   end
	   
	   @page_title = @post.post_title
	   @meta_keywords = @meta_keywords + ", " + @post.post_title

	   respond_to do |format|
	     format.html { render :action=>"show"}
	     format.json { render :json => @post.ajax_attrs(@role) }
	   end
	 end

	 # GET /posts/1
	 # GET /posts/1.json
	 def show
	   respond_to do |format|
             format.html { render :partial =>"roxiware/blog/post/editform" }
	     format.json { render :json => @post.ajax_attrs(@role) }
	   end
	 end

	 def edit
	   @post_category = @post.category_name
	   respond_to do |format|
             format.html { render :partial =>"roxiware/blog/post/editform" }
	     format.json { render :json => @post.ajax_attrs(@role) }
	   end
	 end

	 # GET /posts/1
	 # GET /posts/1.json
	 def edit_by_title
	   @post = Roxiware::Blog::Post.where(:guid=>request.env['REQUEST_PATH']).first
	   raise ActiveRecord::RecordNotFound if @post.nil?
	   authorize! :edit, @post

	   respond_to do |format|
             format.html { render :partial =>"roxiware/blog/post/editform" }
	     format.json { render :json => @post.ajax_attrs(@role) }
	   end
	 end

	 # GET /posts/new
	 # GET /posts/new.json
	 def new
           @robots="noindex,nofollow"
	   authorize! :create, Roxiware::Blog::Post
	   @post = Roxiware::Blog::Post.new({:person_id=>current_user.person.id, 
	                                     :blog_class=>(params[:blog_class] || "blog"),
					     :post_date=>DateTime.now.utc, 
					     :post_content=>"Content",
					     :post_title=>"Title",
					     :post_status=>"publish"}, :as=>"")

	   # We need to pass the post category in separately as on new post creation, the
	   # category joins are not yet created for the post.
	   @post_category = Roxiware::Param::Param.application_param_val('blog', 'default_category')
	   respond_to do |format|
             format.html { render :partial =>"roxiware/blog/post/editform" }
	     format.json { render :json => @post.ajax_attrs(@role) }
	   end
	 end

	 # POST /posts
	 # POST /posts.json

	 def create
	   params[:post_date] = DateTime.now
	   @post = Roxiware::Blog::Post.new({:person_id=>current_user.person.id, 
					     :post_date=>DateTime.now.utc, 
	                                     :blog_class=>(params[:blog_class] || "blog"),
					     :post_content=>"Content",
					     :post_title=>"Title", 
					     :comment_permissions=>"default",
					     :post_status=>"publish"}, :as=>"")

	   if((@role == "super") || (@role == "admin")) 
	       params[:blog_post][:post_content] = Sanitize.clean(params[:blog_post][:post_content], Roxiware::Sanitizer::EXTENDED_SANITIZER)
	   else
	       params[:blog_post][:post_content] = Sanitize.clean(params[:blog_post][:post_content], Roxiware::Sanitizer::BASIC_SANITIZER)
           end

	   respond_to do |format|
	       if @post.update_attributes(params[:blog_post], :as=>@role)
		  format.html { redirect_to @post, :notice => 'Blog post was successfully created.' }
		  format.json { render :json => @post.ajax_attrs(@role) }
	       else
		  format.html { redirect_to @post, :alert => 'Failure in creating blog post.' }
		  format.json { render :json=>report_error(@post)}
	       end
	   end
	 end

	 # PUT /posts/1
	 # PUT /posts/1.json
	 def update
	   if params[:blog_post].include?(:post_content)
	       if((@role == "super") || (@role == "admin")) 
		   params[:blog_post][:post_content] = Sanitize.clean(params[:blog_post][:post_content], Roxiware::Sanitizer::EXTENDED_SANITIZER)
	       else
		   params[:blog_post][:post_content] = Sanitize.clean(params[:blog_post][:post_content], Roxiware::Sanitizer::BASIC_SANITIZER)
	       end
           end
	   respond_to do |format|
	       if @post.update_attributes(params[:blog_post], :as=>@role)
		  format.html { redirect_to @post.post_link, :notice => 'Blog post was successfully updated.' }
		  format.json { render :json => @post.ajax_attrs(@role) }
	       else
		  format.html { redirect_to @post, :alert => 'Failure updating post.' }
		  format.json { render :json=>report_error(@post)}
	       end
	   end
	 end

	 # DELETE /posts/1
	 # DELETE /posts/1.json
	 def destroy_by_title
	   @post = Roxiware::Blog::Post.where(:guid=>request.env['REQUEST_PATH']).first
	   raise ActiveRecord::RecordNotFound if @post.nil?
	   authorize! :destroy, @post
	   @post.destroy
	   respond_to do |format|
	     if !@post.destroy
	       format.json { render :json=>report_error(@post)}
	       format.html { redirect_to @post, :alert => 'Failure deleting blog post.' }
	     else
	       format.json { render :json=>{}}
	     end
	   end
	 end

	 # DELETE /posts/1
	 # DELETE /posts/1.json
	 def destroy
	   @post.destroy
	   respond_to do |format|
	     if !@post.destroy
	       format.json { render :json=>report_error(@post)}
	     else
	       format.json { render :json=>{}}
	     end
	   end
	 end
      end
   end
end


