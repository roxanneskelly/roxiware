class AddThumbnailToPeople < ActiveRecord::Migration
  def change
    add_column :people, :thumbnail_url, :string
  end
end
