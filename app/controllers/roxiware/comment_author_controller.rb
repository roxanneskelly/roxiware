module Roxiware
    class CommentAuthorController < ApplicationController
         application_name "comment_authors"

	 before_filter do
           @role = "guest"
	   @role = current_user.role unless current_user.nil?
           
	 end

         # retrieve information associated with the comment author
	 # such as forum topics read, etc.  Must be called with an
	 # auth token

         def get
	     begin
		 if user_signed_in?
		    @comment_author = Roxiware::CommentAuthor.comment_author_from_user(current_user)
		    @comment_author.save!
		 elsif cookies[:ext_oauth_token].present?
		 
		    @comment_author = Roxiware::CommentAuthor.comment_author_from_token(cookies[:ext_oauth_token] || params[:ext_oauth_token])
		    @comment_author.save!
		 end
		 rescue Exception=>e
		     logger.error e.message
		     logger.error e.backtrace.join("\n")
		     @comment_author.errors.add("exception", e.message()) if @comment_author.present?
		 end
	     respond_to do |format|
                 if (@comment_author.errors.blank?)
		     format.json { render :json => @comment_author.ajax_attrs("") }
		 else
		     format.json { render :json=>report_error(@comment-author)}
		 end
	     end
	 end
    end
end
