class AddTaxonomyId < ActiveRecord::Migration
  def change
    add_index :term_taxonomies, :name, :unique=>true
  end
end
