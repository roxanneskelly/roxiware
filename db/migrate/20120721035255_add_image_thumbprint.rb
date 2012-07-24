class AddImageThumbprint < ActiveRecord::Migration
  def change
    add_column :people, :image_thumbprint, :string
    add_column :gallery, :image_thumbprint, :string
    add_column :gallery_items, :image_thumbprint, :string
    add_column :portfolio_entries, :image_thumbprint, :string
  end
end
