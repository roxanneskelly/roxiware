class CreateTermRelationships < ActiveRecord::Migration
  def change
    create_table :term_relationships do |t|
      t.integer :term_object_id, :null=>false
      t.string :term_object_type, :null=>false
      t.references :term, :null=>false
      t.timestamps
    end
  end
end
