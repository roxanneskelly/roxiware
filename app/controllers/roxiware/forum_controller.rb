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
      @board_data = {}
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
      authorize! :read, @board
      @topics_data = ActiveSupport::JSON.decode(cookies[:forum_topics_read] || "{}")
      respond_to do |format|
          format.html 
      end
    end


    # Edit board settings
    # GET /forum/:id/edit
    def edit
      @board = Roxiware::Forum::Board.find(params[:id])
      raise ActiveRecord::RecordNotFound if @board.nil?
      authorize! :update, @board
      respond_to do |format|
	format.html { render :partial =>"roxiware/forum/edit_board" }
      end
    end

    # Update board settings
    # PUT /forum/:id
    def update
      @board = Roxiware::Forum::Board.find(params[:id])
      raise ActiveRecord::RecordNotFound if @board.nil?
      authorize! :update, @board
      respond_to do |format|
          if @board.update_attributes(params[:forum_board], :as=>@role)
	      format.json { render :json => @board.ajax_attrs(@role) }
	  else
	      format.json { render :json=>report_error(@board)}
	  end
      end
    end


    # Show a topic and posts
    def show_topic
      @title = @title + " : Forum"

      @topic = Roxiware::Forum::Topic.find_by_topic_link(request.path)
      raise ActiveRecord::RecordNotFound if @topic.nil?
      authorize! :read, @topic

      comments = @topic.posts.visible(current_user)
      topics_info = ActiveSupport::JSON.decode(cookies[:forum_topics_read] || "{}") || {}
      @topic_last_read = topics_info[@topic.id.to_s] || 0
      topics_info[@topic.id.to_s] = Time.now().to_i
      puts "TOPICS #{topics_info.to_json}"
      cookies[:forum_topics_read] = topics_info.to_json
      
      # create comment hierarchy
      @comments = {}
      comments.each do |comment|
          @comments[comment.parent_id] ||= {:children=>[]}
          @comments[comment.id] ||= {:children=>[]}
          @comments[comment.parent_id][:children] << comment.id
          @comments[comment.id][:comment] = comment
          @comments[comment.id][:unread] = (Time.at(@topic_last_read) < comment.comment_date.to_time)
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
              permissions = "board"
	      if(@board.permissions == "moderate") 
	          permissions = "hide"
	      end
	      @topic = @board.topics.create({:title=>params[:title], :permissions=>"board"}, :as=>"")
	      params[:comment_date] = DateTime.now
	      person_id = (current_user && current_user.person)?current_user.person.id : -1
	      # always publish the first comment.  Whether it's shown or hidden is determined
	      # by whether the topic is hidden
	      @post = @topic.posts.build({:parent_id=>0,
				          :comment_status=> ((@topic.resolve_comment_permissions == "open") ? "publish" : "moderate"),
					  :comment_content=>params[:comment_content],
					  :comment_date=>DateTime.now.utc}, :as=>"")

					  
	      if user_signed_in?
	          @post_author = Roxiware::CommentAuthor.comment_author_from_params(:current_user=>current_user)
	      else 
	          @post_author = Roxiware::CommentAuthor.comment_author_from_params(params)
	      end
	      if(@post_author.authtype == "generic")
                  verify_recaptcha(:model=>@post_author, :attribute=>:recaptcha_response_field)
	      end

	      @post_author.comments << @post
	      @post_author.save
	      if (@post_author.errors.present?)
		  @post_author.errors.each do |key, error|
		      @post.errors.add(key, error)
		  end
	      end

	      if(!@post.save) 
	          @post.errors.each do |attr,msg|
		      @topic.errors.add(attr, msg)
		  end
              else
	          @topic.save
              end
           rescue Exception=>e
	       puts e.message
               puts e.backtrace.join("\n")
	       @topic.errors.add("exception", e.message)
	       raise raise ActiveRecord::Rollback
           end
       end
       respond_to do |format|
	   if (@topic.errors.blank?)
	       if(@post.comment_status == "publish")
		   flash[:notice] = "Your topic has been published."
	       end		  
	       @topic.save
	       format.html { redirect_to @topic.topic_link }
	       format.json do
	           ajax_results = @topic.ajax_attrs(@role)
		   ajax_results[:comment_status] = @post.comment_status
	           render :json => ajax_results
	       end
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