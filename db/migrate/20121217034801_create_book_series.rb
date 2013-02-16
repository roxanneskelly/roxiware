class CreateBookSeries < ActiveRecord::Migration
  def change
    create_table :book_series do |t|
      t.string :title
      t.text :description
      t.string :large_image_url
      t.string :image_url
      t.string :thumbnail_url
      t.string :seo_index
      t.timestamps
    end
  end
end
