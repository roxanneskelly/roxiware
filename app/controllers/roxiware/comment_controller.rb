module Roxiware
      class CommentController < ApplicationController
         application_name "comments"

         load_and_authorize_resource :except=>[:create], :class=>"Roxiware::Comment"


	 before_filter do
           @role = "guest"
	   @role = current_user.role unless current_user.nil?
           
	 end

	 def create
	    ActiveRecord::Base.transaction do
		 begin
		     @post_class = params[:root_type].split('::').inject(Object) do |mod, class_name|
			 mod.const_get(class_name)
		     end
		     raise ActiveRecord::RecordNotFound if @post_class.nil?

		     @post=@post_class.find(params[:root_id])
		     raise ActiveRecord::RecordNotFound if @post.nil?

		     params[:comment_date] = DateTime.now
		     person_id = (current_user && current_user.person)?current_user.person.id : -1
		     comment_status = "moderate"
		     comment_status= "publish" if ((@post.resolve_comment_permissions=="open") || (@role=="super" || @role=="admin"))

		     params[:comment_content] = Sanitize.clean(params[:comment_content], Roxiware::Sanitizer::BASIC_SANITIZER)

		     oauth_expired = false
		     @comment = @post.comments.new
		     @comment.assign_attributes(params.merge({
						    :comment_status=>comment_status,
						    :comment_date=>DateTime.now.utc}), :as=>"")
		     if user_signed_in?
			 @comment.comment_author = Roxiware::CommentAuthor.comment_author_from_user(current_user)
		     elsif cookies[:ext_oauth_token].present?
			 @comment.comment_author = Roxiware::CommentAuthor.comment_author_from_token(cookies[:ext_oauth_token])
			 if @comment.comment_author.authtype=="expired"
			     cookies.delete(:ext_oauth_token)
			     oauth_expiry = true
			 end
		     else
			@comment.comment_author= Roxiware::CommentAuthor.comment_author_from_params({:name=>params[:comment_author],
											  :url=>params[:comment_author_url], 
											  :email=>params[:comment_author_email]})
		     end

		     @comment.save
		     @comment.errors.add(:ext_oauth_token, "Your session has expired, please log in again") if oauth_expired
		     verify_recaptcha(:model=>@comment, :attribute=>:recaptcha_response_field) if @comment.errors.blank? && @comment.comment_author.authtype == "generic"

		 rescue Exception=>e
		     logger.error e.message
		     logger.error e.backtrace.join("\n")
		     puts e.message
		     puts e.backtrace.join("\n")
		     @comment.errors.add("exception", e.message()) if @comment.present?
		 end
             end
             respond_to do |format|
	         if (@comment.errors.blank?)
		    if(@comment.comment_status == "publish")
		        flash[:notice] = "Your comment has been published."
		    end
		    @post.save
		    format.html { redirect_to @post.post_link }
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
	   person_id = (current_user && current_user.person)?current_user.person.id : -1
	   respond_to do |format|
               @comment.assign_attributes(params, :as=>@role)
	       if @comment.save
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
	       format.html { redirect_to @comment, :alert => 'Failure deleting comment.' }
	     else
	       format.json { render :json=>{}}
	     end
	   end
	 end
      end
end


