class CreateGallery < ActiveRecord::Migration
   def change
      create_table :gallery do |t|
        t.string :name, :null => false
	t.string :seo_index, :null => false
	t.text   :description
	t.string :image_url
        t.timestamps
      end
   end
end
