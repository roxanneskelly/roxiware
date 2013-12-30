# per-reader info on commented objects
# such as forum topics, blog posts, comments 
class CreateReaderCommentObjectInfo < ActiveRecord::Migration
    def up
	create_table :reader_comment_object_infos do |t|
	  t.integer  :reader_id, :null=>false
	  t.integer  :comment_object_id, :null=>false
	  t.string   :comment_object_type, :hull=>false
	  t.datetime :last_read
	  t.integer  :rating
	  t.boolean  :notify, :default=>false
	end

	# change column type for last post date
	remove_column :forum_topics, :last_post_date
	add_column :forum_topics, :last_post_date, :datetime

        remove_column :forum_boards, :last_post_date	
        add_column :forum_boards, :last_post_date, :datetime
	
	Roxiware::Forum::Topic.reset_column_information
	Roxiware::Forum::Topic.all.each do |topic|
	    topic.last_post_date = topic.posts.first.comment_date if topic.posts.present?
	    topic.comment_count = topic.posts.where(:comment_status=>"publish").count
	    topic.pending_comment_count = topic.posts.count - topic.comment_count
        
            topic.title = "No Title" if topic.title.blank?
            topic.save!
	    topic.destroy if topic.posts.blank?
	end

	Roxiware::Forum::Board.reset_column_information
	Roxiware::Forum::Board.all.each do |board|
	    board.last_post_date = board.posts.first.comment_date if board.posts.present?
	    board.comment_count = board.posts.where(:comment_status=>"publish").count
	    board.pending_comment_count = board.posts.count - board.comment_count
            board.save!
	end
    end

    def down
	# change column type for last post date
	remove_column :forum_topics, :last_post_date
	add_column :forum_topics, :last_post_date, :integer

        remove_column :forum_boards, :last_post_date	
        add_column :forum_boards, :last_post_date, :integer
	
	Roxiware::Forum::Topic.reset_column_information
	Roxiware::Forum::Topic.all.each do |topic|
	    topic.last_post_date = topic.posts.first.comment_date.to_time.to_i if topic.posts.present?
            topic.save!
	end

	Roxiware::Forum::Board.reset_column_information
	Roxiware::Forum::Board.all.each do |board|
	    board.last_post_date = board.posts.last.comment_date.to_time.to_i if board.posts.present?
            board.save!
	end

	drop_table :reader_comment_object_infos
    end
end
