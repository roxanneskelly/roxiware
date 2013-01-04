class CreateBookSeries < ActiveRecord::Migration
  def change
    create_table :book_series do |t|
      t.string :title
      t.text :description
      t.string :large_image
      t.string :image
      t.string :small_image
      t.string :seo_index
      t.timestamps
    end
  end
end
