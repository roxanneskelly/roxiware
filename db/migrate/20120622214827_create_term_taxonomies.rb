class CreateTermTaxonomies < ActiveRecord::Migration
  def change
    create_table :term_taxonomies do |t|
      t.string :name, :null=>false
      t.string :seo_index, :null=>false
      t.text :description
      t.timestamps
    end
  end
end
