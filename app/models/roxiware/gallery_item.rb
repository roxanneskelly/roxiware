module Roxiware
   class GalleryItem < ActiveRecord::Base
     include Roxiware::BaseModel
     self.table_name="gallery_items"
     validates_presence_of :person_id
     validates_presence_of :gallery_id
     belongs_to :person
     belongs_to :gallery
     validates_presence_of :name
     validates_uniqueness_of :name
     validates_uniqueness_of :seo_index
     validates_presence_of :image_url
     validates_presence_of :thumbnail_url

     def full_name
        return self.person.full_name
     end

     edit_attr_accessible :name, :description, :medium, :image_url, :thumbnail_url, :featured, :as=>[:admin, :user, nil]
     edit_attr_accessible :person_id, :seo_index, :as=>[:admin, nil]
     ajax_attr_accessible :name, :description, :medium, :image_url, :thumbnail_url, :featured, :person_id, :full_name, :as=>[:guest]

    before_validation() do
       self.seo_index = self.name.downcase.gsub(/[^a-z0-9]+/i, '-')
    end
   end
end
