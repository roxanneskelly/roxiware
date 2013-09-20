class ExtendCommentAuthors < ActiveRecord::Migration
  def change
    add_column :comment_authors, :thumbnail_url, :string
    add_column :comment_authors, :comments_count, :integer, :default=>0
    add_column :comment_authors, :likes, :integer, :default=>0
    add_column :comment_authors, :blocked, :boolean, :default=>false
  end
end
