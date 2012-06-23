class CreateBlogTermRelationships < ActiveRecord::Migration
  def change
    create_table :blog_term_relationships do |t|
      t.references :blog_post, :null=>false
      t.references :blog_term, :null=>false
      t.timestamps
    end
    add_index :blog_term_relationships, :blog_term_id
    add_index :blog_term_relationships, :blog_post_id
  end
end
