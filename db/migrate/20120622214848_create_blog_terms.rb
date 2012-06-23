class CreateBlogTerms < ActiveRecord::Migration
  def change
    create_table :blog_terms do |t|
      t.references :blog_term_taxonomy, :null=>false
      t.string :name, :null=>false
      t.string :seo_index, :null=>false
      t.timestamps
    end
    add_index :blog_terms, :blog_term_taxonomy_id
  end
end
