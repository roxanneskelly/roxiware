class CreateBooks < ActiveRecord::Migration
  def change
    create_table :books do |t|
      t.string :isbn
      t.string :isbn13
      t.string :title
      t.text :description
      t.string :large_image_url
      t.string :image_url
      t.string :thumbnail_url
      t.string :seo_index
      t.timestamps
    end
    add_index :books, :isbn
    add_index :books, :isbn13
  end
end
