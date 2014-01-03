class AddForumTrendingFeatures < ActiveRecord::Migration
  def up
      # 'hot topic' and 'views' trending
      add_column :forum_topics, :views, :integer,   :default=>0
      add_column :forum_topics, :trend, :float,     :default=>0
      add_column :forum_topics, :last_trend_update, :datetime

      # cached rating/like counters
      add_column :forum_topics, :likes, :integer, :default=>0
      add_column :forum_topics, :unlikes, :integer, :default=>0
      add_column :forum_topics, :rating, :integer, :default=>0

      # used to mark topics as sticky
      add_column :forum_topics, :priority, :integer, :default=>0

      # cache root post id for performance
      add_column :forum_topics, :root_post_id, :integer

      Roxiware::Forum::Topic.reset_column_information
      Roxiware::Forum::Topic.all.each do |topic|
          topic.root_post = topic.comments.first
          topic.last_post = topic.comments.where(:comment_status=>"publish").last
	  topic.save!
      end

      # like/unlike.  Like is 1, unlike is -1, no opinion is 0
      add_column :reader_comment_object_infos, :like, :integer, :default=>0

  end
  def down
      # 'hot topic' and 'views' trending
      remove_column :forum_topics, :views, :integer,   :default=>0
      remove_column :forum_topics, :trend, :float,     :default=>0
      remove_column :forum_topics, :last_trend_update, :datetime

      # cached rating/like counters
      remove_column :forum_topics, :likes, :integer, :default=>0
      remove_column :forum_topics, :unlikes, :integer, :default=>0
      remove_column :forum_topics, :rating, :integer, :default=>0

      # used to mark topics as sticky
      remove_column :forum_topics, :priority, :integer, :default=>0

      # cache root post id for performance
      remove_column :forum_topics, :root_post_id, :integer

      # like/unlike.  Like is 1, unlike is -1, no opinion is 0
      remove_column :reader_comment_object_infos, :like, :integer, :default=>0
  end
end
