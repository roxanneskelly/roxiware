module Roxiware
   module Blog
      class CommentController < ApplicationController
         load_and_authorize_resource :except=>[:create], :class=>"Roxiware::Blog::Comment"

	 before_filter do
           @role = "guest"
	   @role = current_user.role unless current_user.nil?
	 end

	 def index
	   authorize! :read, Roxiware::Blog::Comment
	   person_id = (current_user && current_user.person)?current_user.person.id : -1
           @comments = Roxiware::Blog::Comment.visible(@role, person_id).where(:post_id=>params[:post_id]).order("comment_date DESC")

	   clean_comments = []
	   @comments.each do |comment| 
	     clean_comments << comment.ajax_attrs(@role)
	   end 
	   
	   @post = Roxiware::Blog::Post.find(params[:post_id])
	   respond_to do |format|
	     format.html { redirect_to @post.post_link }
	     format.json { render :json => clean_comments }
             format.rss { render :layout => false }
	   end
	 end

	 # GET /posts/1
	 # GET /posts/1.json
	 def show
	   respond_to do |format|
	     format.html { redirect_to @post.post_link }
	     format.json { render :json => @comment.ajax_attrs(@role) }
	   end
	 end


	 # GET /posts/1
	 # GET /posts/1.json
	 def edit
	   respond_to do |format|
	     format.html { redirect_to @post.post_link }
	     format.json { render :json => @comment.ajax_attrs(@role) }
	   end
	 end

	 # GET /posts/new
	 # GET /posts/new.json
	 def new
	   respond_to do |format|
	     format.html { redirect_to @post.post_link }
	     format.json { render :json => @comment.ajax_attrs(@role) }
	   end
	 end

	 # POST /posts
	 # POST /posts.json
	 def create
	   params[:comment_date] = DateTime.now
	   person_id = (current_user && current_user.person)?current_user.person.id : -1
	   @post = Roxiware::Blog::Post.find(params[:post_id])
	   comment_status = "moderate"
	   comment_status= "publish" if ((@post.comment_permissions=="publish") || (can? :edit, @post))
	   @comment = @post.comments.create({:person_id=>person_id,
	                                           :parent_id=>0,
	                                           :post_id=>params[:post_id],
						   :comment_status=>comment_status,
                                                   :comment_date=>DateTime.now.utc}, :as=>"")
	   if user_signed_in?
	     params[:comment_author]=current_user.person.full_name
	     params[:comment_author_email]=current_user.email
	     params[:comment_author_url]=people_url(current_user.person.seo_index)
	   end
	   respond_to do |format|
	       if @comment.update_attributes(params, :as=>@role)
	          if(@comment.comment_status == "publish")
		     Roxiware::Blog::Post.increment_counter(:comment_count, @post.id)
		  else
		     Roxiware::Blog::Post.increment_counter(:pending_comment_count, @post.id)
		  end		  
		  @post.save
		  format.html { redirect_to @post.post_link, :notice => 'Blog comment was successfully created.' }
		  format.json { render :json => @comment.ajax_attrs(@role) }
	       else
	          error_str = "Failure in creating blog comment:"
	          @comment.errors.each do |error|
		    error_str << error[0].to_s + ":" + error[1] + ","
		  end
		  format.html { redirect_to @post.post_link, :alert => error_str }
		  format.json { render :json=>report_error(@comment)}
	       end
	   end
	 end


	 # PUT /posts/1
	 # PUT /posts/1.json
	 def update
	   @post = Roxiware::Blog::Post.find(params[:post_id])
	   params[:comment_date] = DateTime.now
	   person_id = (current_user && current_user.person)?current_user.person.id : -1
	   logger.debug("UPDATING_ATTRIBUTES:"+params.to_json)
	   old_comment_status = @comment.comment_status
	   respond_to do |format|
	       if @comment.update_attributes(params, :as=>@role)
                  if(old_comment_status == "publish") && (@comment.comment_status != "publish")
	             Roxiware::Blog::Post.decrement_counter(:comment_count, @post.id)
	             Roxiware::Blog::Post.increment_counter(:pending_comment_count, @post.id)
		  elsif (old_comment_status != "publish") && (@comment.comment_status == "publish")
	             Roxiware::Blog::Post.decrement_counter(:pending_comment_count, @post.id)
	             Roxiware::Blog::Post.increment_counter(:comment_count, @post.id)
                  end

		  format.json { render :json => @comment.ajax_attrs(@role) }
	       else
		  format.json { render :json=>report_error(@comment)}
	       end
	   end
	 end

	 # DELETE /posts/1
	 # DELETE /posts/1.json
	 def destroy
	   comment_status = @comment.comment_status
	   respond_to do |format|
	     if !@comment.destroy
	       format.json { render :json=>report_error(@comment)}
	       format.html { redirect_to @comment, :alert => 'Failure deleting blog post.' }
	     else
               @post = Roxiware::Blog::Post.find(params[:post_id])
               if(@comment_status == "publish")
	           Roxiware::Blog::Post.decrement_counter(:comment_count, @post.id)
	       else
		   Roxiware::Blog::Post.decrement_counter(:pending_comment_count, @post.id)
	       end		  
               @post.save
	       format.json { render :json=>{}}
	     end
	   end
	 end
      end
   end
end


