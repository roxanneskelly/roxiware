class AddThumbnailToLayout < ActiveRecord::Migration
  def change
    add_column :layouts, :thumbnail_url, :string
    add_column :layouts, :preview_url, :string
  end
end
