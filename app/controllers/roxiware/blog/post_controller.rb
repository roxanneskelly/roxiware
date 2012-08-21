module Roxiware
   module Blog
      class PostController < ApplicationController
         load_and_authorize_resource :only=>[:show, :update, :edit, :destroy], :class=>"Roxiware::Blog::Post"

	 before_filter do
	   @role = "guest"
	   @role = current_user.role unless current_user.nil?
           @categories = Hash[Roxiware::Terms::Term.categories().map {|category| [category.id, category]  }]
	 end
	 

	 before_filter :add_nav, :only=>[:index_by_date, :show_by_title]

	 def index_by_date
	   @enable_blog_edit = true
	   authorize! :read, Roxiware::Blog::Post
	   page = (params[:page] || 1).to_i
	   conditions = {}
	   person_id = (current_user && current_user.person)?current_user.person.id : -1
	   if params[:format] == "rss"
              num_posts = [(params[:max] || Roxiware.blog_posts_per_feed).to_i, Roxiware.max_blog_posts_per_feed].min
	   else
              num_posts = [(params[:max] || Roxiware.blog_posts_per_page).to_i, Roxiware.max_blog_posts_per_page].min
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
              conditions[:terms] = {:term_taxonomy_id=>Roxiware::Terms::TermTaxonomy::CATEGORY_ID, :seo_index=>params[:category]}
	   end
	   if params.has_key?(:tag)
              conditions[:terms] = {:term_taxonomy_id=>Roxiware::Terms::TermTaxonomy::TAG_ID, :seo_index=>params[:tag]}
	   end
	   if conditions.has_key?(:terms)
	     @posts = Roxiware::Blog::Post.joins(:terms).visible(@role, person_id)
	   else 
	     @posts = Roxiware::Blog::Post.visible(@role, person_id)
	   end

           @posts = @posts.includes(:term_relationships, :terms).where(conditions).order("post_date DESC").limit(num_posts+1).offset(num_posts*(page-1))

           if (@posts.length == num_posts+1)
	      @posts.pop
	      @next_page_link = url_for(:page=>page+1, :max=>num_posts)
	   end
	   if(page > 1)
	      @prev_page_link = url_for(:page=>page-1, :max=>num_posts)
	   end
	      

	   respond_to do |format|
	     format.html do 
               @title = "Blog"
	       @meta_description = @title
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
             format.rss { render :layout => false, :action=>"index" }
	   end
	 end

	 # GET /posts/1
	 # GET /posts/1.json
	 def show_by_title
	   @enable_blog_edit = true
	   @post = Roxiware::Blog::Post.where(:guid=>request.path).first
	   raise ActiveRecord::RecordNotFound if @post.nil?
	   authorize! :read, @post

	   conditions = {}
	   person_id = ((current_user && current_user.person)?current_user.person.id : -1)

           comments = Roxiware::Blog::Comment.visible(@role, person_id).where(:post_id=>@post.id).order("comment_date DESC")

           # create comment hierarchy
	   @comments = {0=>{:comment=>nil, :children=>[]}}
	   comments.each do |comment|
	     @comments[comment.id] = {:comment=>comment, :children=>[]}
	   end

	   @comments.each do |key, value|
	     if (value[:comment]  && @comments.has_key?(value[:comment].parent_id))
	        @comments[value[:comment].parent_id][:children] << key
             end
	   end

	   logger.debug @comments.to_json

	   @title = @post.post_title
	   @meta_description = @title
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
	     format.json { render :json => @post.ajax_attrs(@role) }
	   end
	 end

	 def edit
	   respond_to do |format|
	     format.json { render :json => @post.ajax_attrs(@role) }
	   end
	 end

	 # GET /posts/1
	 # GET /posts/1.json
	 def edit_by_title
	   @post = Roxiware::Blog::Post.where(:guid=>request.env['REQUEST_PATH']).first
	   raise ActiveRecord::RecordNotFound if @post.nil?
	   authorize! :read, @post

	   @title = @title + " : Blog"
	   @meta_description = @title
	   @meta_keywords = @meta_keywords + ", " + @post.post_title

	   respond_to do |format|
	     format.html { render :action=>"edit"}
	     format.json { render :json => @post.ajax_attrs(@role) }
	   end
	 end

	 # GET /posts/new
	 # GET /posts/new.json
	 def new
	   authorize! :create, Roxiware::Blog::Post
	   @post = Roxiware::Blog::Post.new({:person_id=>current_user.person.id, 
					     :post_date=>DateTime.now.utc, 
					     :post_content=>"Content",
					     :post_title=>"Title", :category_name=>"News"}, :as=>"")


	   respond_to do |format|
	     format.html # new.html.erb
	     format.json { render :json => @post.ajax_attrs(@role) }
	   end
	 end

	 # POST /posts
	 # POST /posts.json

	 def create
	   params[:post_date] = DateTime.now
	   @post = Roxiware::Blog::Post.new({:person_id=>current_user.person.id, 
					     :post_date=>DateTime.now.utc, 
					     :post_content=>"Content",
					     :post_title=>"Title"}, 
					     :comment_permissions=>((Roxiware.blog_moderate_comments)?"moderate":"publish"), :as=>"")
	   
	   respond_to do |format|
	       if @post.update_attributes(params, :as=>@role)
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
	 def update_by_title
	   @post = Roxiware::Blog::Post.where(:guid=>request.env['REQUEST_PATH']).first
	   raise ActiveRecord::RecordNotFound if @post.nil?
	   authorize! :edit, @post

	   respond_to do |format|
	       if @post.update_attributes(params, :as=>@role)
		  format.html { redirect_to @post.post_link, :notice => 'Blog post was successfully updated.' }
		  format.json { render :json => @post.ajax_attrs(@role) }
	       else
		  format.html { redirect_to @post, :alert => 'Failure updating post.' }
		  format.json { render :json=>report_error(@post)}
	       end
	   end
	 end

	 # PUT /posts/1
	 # PUT /posts/1.json
	 def update
	   respond_to do |format|
	       if @post.update_attributes(params, :as=>@role)
		  format.json { render :json => @post.ajax_attrs(@role) }
	       else
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

	 private

	   def add_nav
	     
	     @calendar_posts = {}
             raw_calendar_posts = Roxiware::Blog::Post.order("post_date DESC").select("id, post_title, post_date, post_link, post_status")

	     published_post_ids = []

	     raw_calendar_posts.each do |post|
	       year = post.post_date.year
	       @calendar_posts[year] ||= {:count=>0, :unpublished_count=>0, :monthly=>{}}
	       @calendar_posts[year][:monthly][post.post_date.month] ||= {:count=>0, :unpublished_count=>0, :name=>post.post_date.strftime("%B"), :posts=>[]}
	       @calendar_posts[year][:monthly][post.post_date.month][:posts] << {:title=>post.post_title, :published=>(post.post_status == "publish"), :link=>post.post_link}
	       if post.post_status == "publish"
                  @calendar_posts[year][:count] += 1
	          @calendar_posts[year][:monthly][post.post_date.month][:count] += 1
		  published_post_ids << post.id
               elsif can? :edit, post
                  @calendar_posts[year][:unpublished_count] += 1
	          @calendar_posts[year][:monthly][post.post_date.month][:unpublished_count] += 1
               end
	     end

	  end
      end
   end
end


