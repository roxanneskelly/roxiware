require 'msgpack'

class Roxiware::ForumController < ApplicationController
    include Roxiware::ApplicationControllerHelper
    application_name "forum"

    MAX_COOKIE_SIZE = 4000

    before_filter do
        @title = @title + " / Forum"
        @role = "guest"
        @role = current_user.role unless current_user.nil?
        begin
            if user_signed_in?
                @reader = Roxiware::CommentAuthor.comment_author_from_user(current_user)
            elsif cookies[:ext_oauth_token].present?
                @reader = Roxiware::CommentAuthor.comment_author_from_token(cookies[:ext_oauth_token])
                cookies.delete(:ext_oauth_token) if @reader.authtype=="expired"
            else
                @reader = nil
            end
        rescue Exception=>e
            logger.error e.message
            logger.error e.backtrace.join("\n")
            @reader = nil
        end
    end

    # Front page of forum, listing all boards in board groups
    # GET
    def index
        # grab the board groups.  View will use the 'boards' off of the board group to list the boards
        @forum_board_groups = Roxiware::Forum::BoardGroup.includes(:boards).order(:display_order)
        @changed_topic_count = {}
        topic_query = Roxiware::Forum::Topic.visible(current_user)
        @topics = Hash[topic_query.collect{|topic| [topic.id, topic]}]
        if @reader.present?
            boards_last_read = Hash[Roxiware::ReaderCommentObjectInfo.where(:reader_id=>@reader.id, :comment_object_type=>"Roxiware::Forum::Board").collect{|reader_info| [reader_info.comment_object_id, reader_info.last_read]}]
            reader_forum_topics_join = Roxiware::ReaderCommentObjectInfo.joins("INNER JOIN forum_topics on forum_topics.id = reader_comment_object_infos.comment_object_id")
            topics_readers = reader_forum_topics_join.where("reader_comment_object_infos.reader_id=? AND reader_comment_object_infos.comment_object_type='Roxiware::Forum::Topic'",
                                                          @reader.id)
            topics_last_read = Hash[topics_readers.select(:last_read, :comment_object_id).collect{|reader_info| [reader_info.comment_object_id, reader_info.last_read]}]

            @topics.each do |topic_id, topic|
                @changed_topic_count[topic.board_id] ||= 0
                last_read = DateTime.new(0)
                last_read = topics_last_read[topic.id] if topics_last_read[topic.id].present?
                last_read = boards_last_read[topic.board_id] if  (boards_last_read[topic.board_id] || DateTime.new(0)) > last_read
                @changed_topic_count[topic.board_id] += 1 if (last_read < topic.last_post_date)
            end
        elsif params["last_read"].present?
            # for each board, get a count of topics that are new
            @topics.each do |topic_id, topic|
                @changed_topic_count[topic.board_id] ||= 0
                @changed_topic_count[topic.board_id] += 1 if params[:last_read][topic.board_id.to_s].blank?
                # this will also 'next' if the board hasn't been found.
                next unless params[:last_read][topic.board_id.to_s].is_a?(Hash)

                # determine if there's a general last read date for the forum
                last_read = Time.at((params[:last_read][topic.board_id.to_s]["0"] || "0").to_i).to_datetime

                # also get the last read time for the topic
                topic_last_read = Time.at((params[:last_read][topic.board_id.to_s][topic_id.to_s] || "0").to_i).to_datetime

                # if the latest topic last_read is greater than the general one, use it
                topic_last_read = last_read if last_read > topic_last_read
                @changed_topic_count[topic.board_id] += 1 if topic_last_read < topic.last_post_date
            end
        else
            @topics.each do |topic_id, topic|
                @changed_topic_count[topic.board_id] ||= 0
                @changed_topic_count[topic.board_id] += 1
            end
        end

        respond_to do |format|
            format.html
            format.json do
                forum_board_info = {}
                @forum_board_groups.each do |board_group|
                    board_group.boards.each do |board|
                        forum_board_info[board.id] = board.ajax_attrs(@role)
                        forum_board_info[board.id]["new_topics"] = @changed_topic_count[board.id] || 0
                    end
                end
                render :json=>forum_board_info
            end
        end
    end

    # Update board settings
    # PUT /forum
    def update_all
        raise ActiveRecord::RecordNotFound unless params[:mark_all_as_read].present?
        raise ActiveRecord::RecordNotFound unless @reader.present?

        # delete all reader infos where no metadata has been set
        Roxiware::ReaderCommentObjectInfo.only_last_read.where(:comment_object_type=>'Roxiware::Forum::Topic', :reader_id=>@reader.id).destroy_all
        Roxiware::ReaderCommentObjectInfo.update_all("last_read=datetime('now')",
                                                     ['comment_object_type="Roxiware::Forum::Topic" AND reader_id=\?', @reader.id])

        # mark existing info object as currently read
        Roxiware::Forum::Board.all.each do |board|
            board_reader_info = board.reader_infos.where(:reader_id=>@reader.id).first_or_create!
            board_reader_info.assign_attributes({:last_read=>DateTime.now}, :as=>"")
            board_reader_info.save!
        end
        respond_to do |format|
            format.json { render :json => {}}
        end
    end


    def _get_per_topic_reader_info(topic_ids)
        reader_comment_objs = {}
        begin
            # grab all reader settings related to the topic
            if @reader.present?
                # now the ReaderCommentObjectInfo for that author and the given topics.
                reader_comment_objs = Hash[Roxiware::ReaderCommentObjectInfo.where(:comment_object_id=>topic_ids, :comment_object_type=>"Roxiware::Forum::Topic", :reader_id=>@reader.id).collect{|obj_info| [obj_info.comment_object_id, obj_info]}]
            end
        rescue Exception => e
            logger.error e.message
            logger.error e.backtrace.join("\n")
        end
        reader_comment_objs
    end

    def _topics_sort(board)
        result = board.topics.visible(current_user).order("priority DESC").order("last_post_date DESC")
        result = result.where("comment_count > 0") if current_user.blank? || !current_user.is_admin?
        result.each do |topic|
            puts "TOPIC #{ topic.title } #{topic.comment_count}"
        end
        return result
    end

    # Show topics in a specific board
    # GET /forum/:id
    def show
        boards = Roxiware::Forum::Board.ordered().visible(current_user)
        boards.each do |board|
            @next_board = board if @board.present?
            break if @board.present?
            @board = board if params[:id] == board.seo_index
            @prev_board = board unless @board.present?
        end
        raise ActiveRecord::RecordNotFound if @board.nil?
        authorize! :read, @board
        @unread_post_counts = {}

        # get the topic last read info.  @unread_post_counts will end up with
        # the number of unread posts for each topic, if the topic has ever been read
        if @reader.present?
            board_reader_info = @board.reader_infos.where(:reader_id=>@reader.id).first
            base_date = board_reader_info.last_read if board_reader_info.present?
            base_date ||= DateTime.new(0)
            unread_post_query = @board.topics.
                                joins("LEFT JOIN reader_comment_object_infos on forum_topics.id = reader_comment_object_infos.comment_object_id AND reader_comment_object_infos.comment_object_type='Roxiware::Forum::Topic' AND reader_comment_object_infos.reader_id=#{@reader.id || 0}").
                                joins("LEFT JOIN comments ON comments.post_id=forum_topics.id AND comments.post_type='Roxiware::Forum::Topic'").
                                where("comments.comment_status='publish'").
                                where("comments.comment_date > ?", base_date.to_formatted_s(:db)).
                                where("reader_comment_object_infos.id IS NULL OR comments.comment_date > reader_comment_object_infos.last_read").
                                group("forum_topics.id").select("forum_topics.id, COUNT(comments.id) as num_new_posts, reader_comment_object_infos.id as reader_info_id, forum_topics.comment_count")

            # unread_post_query will list posts that haven't been read at all, but won't list any that have been fully read.
            @unread_post_counts = Hash[unread_post_query.collect{|topic| [topic.id, topic.num_new_posts]}]
        else
            topics_last_read = {}
            (params[:last_read] || {}).each do |topic_id, topic_last_read|
                begin
                    topics_last_read[topic_id.to_i] =  Time.at(topic_last_read.to_i).to_datetime
                rescue Exception=>e
                end
            end
            comments = Roxiware::Comment.joins("INNER JOIN forum_topics on comments.post_id=forum_topics.id AND comments.post_type='Roxiware::Forum::Topic'").
                                          where("forum_topics.board_id=?", @board.id).
                                          where("comments.id IS NOT NULL").
                                          select("comments.comment_date, comments.post_id")
            comments.each do |comment|
                unread_date = (topics_last_read[0] || DateTime.new(0))
                unread_date = topics_last_read[comment.post_id] if topics_last_read.include?(comment.post_id) && (topics_last_read[comment.post_id] > unread_date)
                if  (unread_date < comment.comment_date)
                    @unread_post_counts[comment.post_id] ||= 0
                    @unread_post_counts[comment.post_id] += 1
                end
            end
        end

        respond_to do |format|
            format.html do
                @topics = _topics_sort(@board).includes({:root_post=>:comment_author, :last_post=>:comment_author})
                render
            end
            format.json do
                topic_info=@board.topics.select([:id, :comment_count, :pending_comment_count]).collect do |topic|
                    [topic.id,
                        @unread_post_counts.include?(topic.id) ?
                        {:num_posts=>topic.post_count, :num_new_posts=>[topic.post_count, @unread_post_counts[topic.id]].min, :changed=>(@unread_post_counts[topic.id] > 0)} :
                        {:num_posts=>topic.post_count, :num_new_posts=>0, :changed=>false}]
                end
                render :json=>Hash[topic_info]
            end
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

    # Edit board settings
    # GET /forum/:id/edit
    def new
        @board = Roxiware::Forum::Board.new
        authorize! :create, @board
        respond_to do |format|
            format.html { render :partial =>"roxiware/forum/edit_board" }
        end
    end


    # Create a board
    # POST /forum
    def create
        @board = Roxiware::Forum::BoardGroup.order(:display_order).last.boards.build
        @board.assign_attributes(params[:forum_board], :as=>@role)
        @board.display_order = Roxiware::Forum::Board.maximum('display_order')+1;
        respond_to do |format|
            if @board.save
                format.html { redirect_to @board, :notice => 'Forum Board was successfully created.' }
                format.json { render :json => @board.ajax_attrs(@role) }
            else
                format.html { redirect_to @board, :alert => 'Failure in creating forum board.' }
                format.json { render :json=>report_error(@board)}
            end
        end
    end

    # Update board settings
    # PUT /forum/:id
    def update
        @board = Roxiware::Forum::Board.where(:id=>params[:id]).first
        raise ActiveRecord::RecordNotFound if @board.nil?
        authorize! :update, @board unless (params[:mark_all_as_read] && params[:forum_board].blank?)
        ActiveRecord::Base.transaction do
            begin
                if params[:mark_all_as_read] && @reader.present?
                    # delete all reader infos where no metadata has been set
                    Roxiware::ReaderCommentObjectInfo.only_last_read.where(:comment_object_id=>@board.topic_ids, :comment_object_type=>'Roxiware::Forum::Topic', :reader_id=>@reader.id).destroy_all

                    # mark existing info object as currently read
                    Roxiware::ReaderCommentObjectInfo.update_all("last_read=datetime('now')", ["comment_object_id IN (?) AND comment_object_type='Roxiware::Forum::Topic' AND reader_id=\?", @board.topic_ids, @reader.id])
                    board_reader_info = @board.reader_infos.where(:reader_id=>@reader.id).first_or_create!
                    board_reader_info.assign_attributes({:last_read=>DateTime.now}, :as=>"")
                    board_reader_info.save!
                end

                if params[:forum_board].present?
                    @board.assign_attributes(params[:forum_board], :as=>@role)
                    @board.save

                    if(params[:forum_board][:display_order].present? && params[:forum_board][:board_group_id].present?)
                        Roxiware::Forum::BoardGroup.all.each do |board_group|
                            boards = board_group.boards.order(:display_order).select{|board| board.id != @board.id}.collect{|board| board}
                            if(params[:forum_board][:board_group_id].to_i == board_group.id)
                                boards.insert(params[:forum_board][:display_order].to_i, @board)
                            end
                            order = 0
                            boards.each do |board|
                                board.display_order = order
                                order += 1
                                board.save!
                            end
                            board_group.boards = boards
                        end
                    end
                end
            rescue Exception=>e
                logger.error(e.message)
                logger.error(e.backtrace.join("\n"))
                @board.errors.add("exception", e.message)
                raise ActiveRecord::Rollback
            end
            if(@board.errors.present?)
                raise ActiveRecord::Rollback
            end
        end
        respond_to do |format|
            unless @board.errors.present?
                format.json { render :json => @board.ajax_attrs(@role) }
            else
                format.json { render :json=>report_error(@board)}
            end
        end
    end


    # Show a topic and posts
    def show_topic
        @topic = Roxiware::Forum::Topic.where(:topic_link=>request.path.chomp(File.extname(request.path))).includes(:comments).first
        raise ActiveRecord::RecordNotFound if @topic.nil?
        authorize! :read, @topic

        @board = @topic.board
        @topics = _topics_sort(@board).select("forum_topics.last_post_id,forum_topics.topic_link, forum_topics.id").includes(:last_post);

        if @reader.present?
            board_reader_info = @board.reader_infos.where(:reader_id=>@reader.id).first
            @per_topic_reader_info = _get_per_topic_reader_info(@topics.collect{|topic|topic.id})
            @per_topic_last_read = Hash[@per_topic_reader_info.collect{|topic_id, info| [topic_id, info.last_read]}]

            @reader_topic_info = @per_topic_reader_info[@topic.id] || Roxiware::ReaderCommentObjectInfo.new
            @reader_topic_info.reader_id = @reader.id
            @reader_topic_info.comment_object = @topic

            @topic_last_read = @reader_topic_info.last_read if @reader_topic_info.present?
            @topic_last_read ||= DateTime.new(0)
            @topic_last_read = board_reader_info.last_read if (board_reader_info.present? && (board_reader_info.last_read > @topic_last_read))
            @reader_topic_info.last_read = DateTime.now()
            @reader_topic_info.reader = @reader
            @reader_topic_info.save!
        elsif params["last_read"].present?
            @per_topic_last_read = Hash[params[:last_read].collect{|topic_id, last_read| [topic_id.to_i, Time.at(last_read.to_i).to_datetime]}]
            @topic_last_read = @per_topic_last_read[@topic.id] || DateTime.new()
            @topic_last_read = @per_topic_last_read[0] if (@per_topic_last_read[0].present? && (@per_topic_last_read[0] > @topic_last_read))
        else
            @per_topic_last_read = {}
            @topic_last_read = DateTime.new(0)
        end

        new_comments=false
        comments = @topic.comments.visible(current_user).order("comment_date ASC")
        # create comment hierarchy
        @comments = {}
        comments.each do |comment|
            @comments[comment.parent_id] ||= {:children=>[]}
            @comments[comment.id] ||= {:children=>[]}
            @comments[comment.parent_id][:children] << comment.id
            @comments[comment.id][:comment] = comment
            @comments[comment.id][:unread] = (Time.at(@topic_last_read) < comment.comment_date)
            new_comments = true if (Time.at(@topic_last_read) < comment.comment_date)
        end

        last_posts = @topics.collect{|topic| topic.last_post_id}
        topic_found = false
        @topics.each do |topic|
            if(topic.id != @topic.id)
                @next_topic = topic unless topic_found
                @prev_topic ||= topic if topic_found
                last_post = topic.last_post
                next if last_post.blank?
                @next_new_topic = topic if !topic_found && (last_post.comment_date  > (@per_topic_last_read[topic.id] || @per_topic_last_read[0] || DateTime.new(0)))
                @prev_new_topic = topic if topic_found && (last_post.comment_date  > (@per_topic_last_read[topic.id] || @per_topic_last_read[0] || DateTime.new(0)))
            else
                topic_found = true
            end
            break if @prev_new_topic.present?
        end

        respond_to do |format|
            format.html do
                begin
                    if( !is_robot? && @reader.present? && new_comments)
                        @topic.views += 1
                        @topic.save!
                    end
                rescue Exception=>e
                end
            end
            format.json do
                begin
                    if( !is_robot? && @reader.present? && new_comments)
                        @topic.views += 1
                        @topic.save!
                    end
                rescue Exception=>e
                end
                topic_info = @topic.ajax_attrs(@role)
                topic_info[:unread] = comments.select{|comment| comment.comment_date > @topic_last_read}.collect{|comment| comment.id}
                render :json=>topic_info
            end
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
            @topic.assign_attributes(params[:forum_topic], :as=>@role)
            if @topic.save
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
        @board = Roxiware::Forum::Board.find_by_seo_index(params[:forum_id])
        raise ActiveRecord::RecordNotFound if @board.nil?
        authorize! :create_topic, @board

        ActiveRecord::Base.transaction do
            begin
                permissions = "board"
                if(@board.permissions == "moderate")
                    permissions = "hide"
                end

                @topic = @board.topics.new
                # the associated comment will not increment the comment count of this post, as
                @topic.assign_attributes({:title=>params[:title], :permissions=>"board"}, :as=>"")

                params[:comment_date] = DateTime.now
                person_id = (current_user && current_user.person)?current_user.person.id : -1
                # always publish the first comment.  Whether it's shown or hidden is determined
                # by whether the topic is hidden

                @post = @topic.posts.new
                oauth_expired = false
                comment_status = ((@topic.resolve_comment_permissions == "open") ? "publish" : "moderate")
                comment_status = "publish" if current_user.present? && current_user.is_admin?
                @post.assign_attributes({:parent_id=>0,
                                            :comment_status=>comment_status,
                                            :comment_content=>params[:comment_content],
                                            :comment_date=>DateTime.now.utc},
                                        :as=>"")

                if @reader.blank?
                    @post.comment_author= Roxiware::CommentAuthor.comment_author_from_params({:name=>params[:comment_author],
                                                                                                 :url=>params[:comment_author_url],
                                                                                                 :email=>params[:comment_author_email]})
                else
                    @post.comment_author = @reader
                end

                @topic.comment_count = ((comment_status == "publish") ? 1 : 0)
                @topic.pending_comment_count = ((comment_status != "publish") ? 1 : 0)
                @topic.save

                @topic.errors.add(:ext_oauth_token, "Your session has expired, please log in again") if (@reader.present? && (@reader.authtype == "expired"))
                verify_recaptcha(:model=>@topic, :attribute=>:recaptcha_response_field) if @reader.blank? && @topic.errors.blank?


                # if the user is logged in (not generic), generate an object to hold
                # stats, has-read info, etc.
                if(@topic.errors.blank? && @reader.present?)
                    @reader_topic_info = Roxiware::ReaderCommentObjectInfo.new
                    @reader_topic_info.reader = @reader
                    @reader_topic_info.comment_object = @topic
                    @reader_topic_info.last_read = DateTime.now();
                    raise Exception.new("Couldn't create reader info") unless @reader_topic_info.save
                end
            rescue Exception=>e
                logger.error(e.message)
                logger.error(e.backtrace.join("\n"))
                @topic.errors.add("exception", e.message)
                raise ActiveRecord::Rollback
            end
            if(@topic.errors.present?)
                raise ActiveRecord::Rollback
            end
        end
        respond_to do |format|
            if (@topic.errors.blank?)
                if(@post.comment_status == "publish")
                    flash[:notice] = "Your topic has been published."
                end
                format.html { redirect_to @topic.topic_link }
                format.json do
                    ajax_results = @topic.ajax_attrs(@role)
                    ajax_results[:comment_status] = @post.comment_status
                    ajax_results[:completion_redirect] = @topic.topic_link
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
