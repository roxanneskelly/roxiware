class AddPostType < ActiveRecord::Migration
  def change
      add_column :blog_posts, :post_type, :string, :default=>"text"
      add_column :blog_posts, :post_image_url, :string
      add_column :blog_posts, :post_thumbnail_url, :string
      add_column :blog_posts, :post_video_url, :string
  end
end
