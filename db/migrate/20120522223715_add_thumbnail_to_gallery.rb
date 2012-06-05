class AddThumbnailToGallery < ActiveRecord::Migration
  def change
    add_column :gallery, :thumbnail_url, :string
  end
end
