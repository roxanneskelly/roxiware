class CreateTerms < ActiveRecord::Migration
  def change
    create_table :terms do |t|
      t.references :term_taxonomy, :null=>false
      t.integer :parent_id, :default=>0
      t.string :name, :null=>false
      t.string :seo_index, :null=>false
      t.timestamps
    end
    add_index :terms, :term_taxonomy_id
  end
end
