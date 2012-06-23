class CreateBlogPosts < ActiveRecord::Migration
  def change
    create_table :blog_posts do |t|
      t.references :person, :null=>false
      t.datetime :post_date
      t.text :post_content
      t.string :post_title, :null=>false
      t.string :post_exerpt
      t.string :post_link
      t.string :post_status, :default=>"new", :null=>false
      t.string :comment_permissions, :default=>"closed"
      t.string :guid
      t.timestamps
    end
    add_index :blog_posts, :person_id
    add_index :blog_posts, :guid
  end
end
