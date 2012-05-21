class CreateArtworks < ActiveRecord::Migration
  def change
    create_table :artworks do |t|
      t.references :artist, :null => false
      t.references :collection, :null => false
      t.string :name, :null => false
      t.text :description
      t.text :materials
      t.string :dimensions
      t.date :created, :null => false
      t.boolean :featured, :default => false
      t.timestamps
    end
  end
end
