module Roxiware
   class GalleryItem < ActiveRecord::Base
     include Roxiware::BaseModel
     self.table_name="gallery_items"
     @@default_image = "unknown_picture"



     validates_presence_of :person_id
     validates_presence_of :gallery_id
     belongs_to :person
     belongs_to :gallery
     validates_presence_of :name
     validates_uniqueness_of :name
     validates_uniqueness_of :seo_index


     define_upload_image_methods

     def person_data
        return self.person.ajax_attrs(:guest)
     end

     edit_attr_accessible :name, :description, :medium, :image_thumbprint, :featured, :as=>[:admin, :user, nil]
     edit_attr_accessible :person_id, :seo_index, :as=>[:admin, nil]
     ajax_attr_accessible :name, :description, :medium, :image_thumbprint, :featured, :person_id, :as=>[:guest]
     ajax_attr_accessible :person_data, :as=>[nil, :guest, :admin, :user]

    before_validation() do
       self.seo_index = self.name.downcase.gsub(/[^a-z0-9]+/i, '-')
       self.description ||= ""
       self.medium ||= ""
    end
   end
end
