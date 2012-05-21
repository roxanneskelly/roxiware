class CreateGalleryItems < ActiveRecord::Migration
  def change
    create_table :gallery_items do |t|
      t.references :person, :null => false
      t.references :gallery, :null => false
      t.string :name, :null => false
      t.string :seo_index, :null => false
      t.text :description
      t.text :medium
      t.string :image_url
      t.string :thumbnail_url
      t.boolean :featured, :default => false
      t.timestamps
    end
  end
end
