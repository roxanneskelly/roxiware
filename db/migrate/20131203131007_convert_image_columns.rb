class ConvertImageColumns < ActiveRecord::Migration
  def change
    change_table :book_series do |t|
      t.rename :image_url, :image
      t.rename :large_image_url, :large_image
      t.rename :thumbnail_url, :thumbnail
    end
    change_table :books do |t|
      t.rename :image_url, :image
      t.rename :large_image_url, :large_image
      t.rename :thumbnail_url, :thumbnail
    end
    change_table :people do |t|
      t.rename :image_url, :image
      t.rename :large_image_url, :large_image
      t.rename :thumbnail_url, :thumbnail
    end
    change_table :gallery do |t|
      t.rename :image_url, :image
      t.rename :thumbnail_url, :thumbnail
    end
    change_table :gallery_items do |t|
      t.rename :image_url, :image
      t.rename :thumbnail_url, :thumbnail
    end
  end
end
