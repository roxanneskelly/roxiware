class FixPeopleImages < ActiveRecord::Migration
  def change
     add_column :people, :large_image_url, :string
  end
end
