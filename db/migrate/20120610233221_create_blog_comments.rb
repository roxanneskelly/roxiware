class CreateBlogComments < ActiveRecord::Migration
  def change
    create_table :blog_comments do |t|
      t.references :post
      t.references :person
      t.integer :parent_id, :default=>0
      t.text :comment_author
      t.text :comment_author_email
      t.text :comment_author_url
      t.datetime :comment_date, :null=>false
      t.text :comment_content, :null=>false
      t.text :comment_status, :null=>false
      t.timestamps
    end
    add_column :blog_posts, :comment_count, :integer, :default=>0
    add_index :blog_comments, :person_id
    add_index :blog_comments, :post_id
  end
end
