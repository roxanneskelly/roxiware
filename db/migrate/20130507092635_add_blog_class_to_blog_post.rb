class AddBlogClassToBlogPost < ActiveRecord::Migration
  def change
    add_column :blog_posts, :blog_class, :string, :default=>"blog"
  end
end
