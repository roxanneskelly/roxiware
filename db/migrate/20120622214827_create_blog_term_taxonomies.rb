class CreateBlogTermTaxonomies < ActiveRecord::Migration
  def change
    create_table :blog_term_taxonomies do |t|
      t.string :name, :null=>false
      t.string :seo_index, :null=>false
      t.text :description
      t.timestamps
    end
  end
end
