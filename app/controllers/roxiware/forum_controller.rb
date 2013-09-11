class Roxiware::ForumController < ApplicationController
    include Roxiware::ApplicationControllerHelper
    application_name "forum"


    before_filter do
        @role = "guest"
        @role = current_user.role unless current_user.nil?
    end

    # Front page of forum, listing all boards in board groups
    # GET
    def index
      @title = @title + " : Forum"

      # grab the board groups.  View will use the 'boards' off of the board group to list the boards
      @forum_board_groups = Roxiware::Forum::BoardGroup.includes(:boards).order(:display_order)

      respond_to do |format|
          format.html 
      end
    end

    # Show topics in a specific board group
    # GET /forum/:id
    def show
      @title = @title + " : Forum"
      @board = Roxiware::Forum::Board.find_by_seo_index(params[:id])
      raise ActiveRecord::RecordNotFound if @board.nil?
      puts "BOARD PERMS #{@board.resolve_permissions}"
      authorize! :read, @board

      respond_to do |format|
          format.html 
      end
    end


    # Show a topic and posts
    def show_topic
      @title = @title + " : Forum"

      puts "REQUEST PATH #{request.path}"
      @topic = Roxiware::Forum::Topic.find_by_topic_link(request.path)
      raise ActiveRecord::RecordNotFound if @topic.nil?
      authorize! :read, @topic

      comments = @topic.posts.visible(current_user)

      # create comment hierarchy
      @comments = {}
      comments.each do |comment|
          @comments[comment.parent_id] ||= {:children=>[]}
          @comments[comment.id] ||= {:children=>[]}
          @comments[comment.parent_id][:children] << comment.id
          @comments[comment.id][:comment] = comment
      end

      respond_to do |format|
          format.html 
      end
    end

    def edit_topic
      @topic = Roxiware::Forum::Topic.find(params[:id])
      raise ActiveRecord::RecordNotFound if @topic.nil?
      authorize! :update, @topic
      respond_to do |format|
	format.html { render :partial =>"roxiware/forum/edit_topic" }
      end
    end

    def update_topic
      @topic = Roxiware::Forum::Topic.find(params[:id])
      raise ActiveRecord::RecordNotFound if @topic.nil?
      authorize! :update, @topic
      respond_to do |format|
          if @topic.update_attributes(params[:forum_topic], :as=>@role)
	      format.json { render :json => @topic.ajax_attrs(@role) }
	  else
	      format.json { render :json=>report_error(@topic)}
	  end
      end
      
    end

    def destroy_topic
      @topic = Roxiware::Forum::Topic.find(params[:id])
      raise ActiveRecord::RecordNotFound if @topic.nil?
      authorize! :destroy, @topic
      respond_to do |format|
          if @topic.destroy
	      format.json { render :json => {}}
	  else
	      format.json { render :json=>report_error(@topic)}
	  end
      end
      
    end

    def create_topic
      @title = @title + " : Forum"
      @board = Roxiware::Forum::Board.find_by_seo_index(params[:forum_id])
      raise ActiveRecord::RecordNotFound if @board.nil?
      authorize! :create_topic, @board

      ActiveRecord::Base.transaction do
          begin
              # first, create the 
	      @topic = @board.topics.create({:title=>params[:title], :permissions=>"board"}, :as=>@role)
	      params[:comment_date] = DateTime.now
	      person_id = (current_user && current_user.person)?current_user.person.id : -1
	      comment_status = "moderate"
	      comment_status= "publish" if (@topic.resolve_comment_permissions=="open") || (@role="super" || @role="admin")
	      @post = @topic.posts.build({:parent_id=>0,
				          :comment_status=>comment_status,
					  :comment_content=>params[:comment_content],
					  :comment_date=>DateTime.now.utc}, :as=>"")
					  puts "POST IS #{@post.inspect}"

					  
	      if user_signed_in?
	          @post_author = @post.create_comment_author({:name=>current_user.person.full_name,
								    :email=>current_user.email,
								    :person_id=>person_id,
								    :url=>"/people/#{current_user.person.seo_index}",
								    :comment_object=>@post,
								    :authtype=>"roxiware"}, :as=>"");
	      else 
	          @post_author = @post.create_comment_author({:name=>params[:comment_author],
								    :email=>params[:comment_author_email],
								    :url=>params[:comment_author_url],
								    :comment_object=>@post,
								    :authtype=>"generic"}, :as=>"");
	      end
              @post_author.save!
	      @post.comment_author = @post_author
	      @post.save!
	      @topic.save!
           rescue Exception=>e
	       puts e.message
               puts e.backtrace.join("\n")
	       @topic.errors.add("exception", e.message)
	       raise raise ActiveRecord::Rollback
           end
       end
       respond_to do |format|
	   if (user_signed_in? || verify_recaptcha(:model=>@topic, :attribute=>:recaptcha_response_field)) && @topic.update_attributes(params, :as=>"") && @topic.errors.empty?
	       if(@post.comment_status == "publish")
		   notice = "Your topic has been published."
	       else
	           notice = "Your topic will be added once it is moderated."
	       end		  
	       @topic.save
	       format.html { redirect_to @topic.topic_link, :notice => notice }
	       format.json { render :json => @topic.ajax_attrs(@role) }
	   else
	       error_str = "Failure in creating topic comment:"
	       @topic.errors.each do |error|
	           error_str << error[0].to_s + ":" + error[1] + ","
	       end
	       format.html { redirect_to @topic.topic_link, :alert => error_str }
	       format.json { render :json=>report_error(@topic)}
	   end
        end
    end
end