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
		   comment_status= "publish" if (@post.resolve_comment_permissions=="open") || (@role="super" || @role="admin")


		   @comment = @post.comments.build({:parent_id=>0,
						    :comment_status=>comment_status,
						    :comment_date=>DateTime.now.utc}, :as=>"")

		   if user_signed_in?
		     @comment_author = @comment.create_comment_author({:name=>current_user.person.full_name,
									    :email=>current_user.email,
									    :person_id=>person_id,
									    :url=>"/people/#{current_user.person.seo_index}",
									    :comment_object=>@comment,
									    :authtype=>"roxiware"}, :as=>"");
		   else 
		     @comment_author = @comment.create_comment_author({:name=>params[:comment_author],
									    :email=>params[:comment_author_email],
									    :url=>params[:comment_author_url],
									    :comment_object=>@comment,
									    :authtype=>"generic"}, :as=>"");
		   end
                   @comment_author.save!
		   @comment.comment_author = @comment_author

               rescue Exception=>e
	           puts e.message
                   puts e.backtrace.join("\n")
               end
	       respond_to do |format|
		   if (user_signed_in? || verify_recaptcha(:model=>@comment, :attribute=>:recaptcha_response_field)) && @comment.update_attributes(params, :as=>"")
		      if(@comment.comment_status == "publish")
			 notice = "Your comment has been published."
		      else
			 notice = "Your comment will be added once it is moderated."
		      end		  
		      @post.save
		      format.html { redirect_to @post.post_link, :notice => notice }
		      format.json { render :json => @comment.ajax_attrs(@role) }
		   else
		      puts @comment.errors.inspect
		      error_str = "Failure in creating blog comment:"
		      @comment.errors.each do |error|
			error_str << error[0].to_s + ":" + error[1] + ","
		      end
		      format.html { redirect_to @post.post_link, :alert => error_str }
		      format.json { render :json=>report_error(@comment)}
		   end
	       end
           end
	 end


	 # PUT /posts/1
	 # PUT /posts/1.json
	 def update
	   person_id = (current_user && current_user.person)?current_user.person.id : -1
	   respond_to do |format|
	       if @comment.update_attributes(params, :as=>@role)
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
	       format.json { render :json=>{}}
	     end
	   end
	 end
      end
end


