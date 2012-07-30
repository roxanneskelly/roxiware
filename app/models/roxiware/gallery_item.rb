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
     validates_uniqueness_of :name, :scope=>:gallery_id
     validates_uniqueness_of :seo_index, :scope=>:gallery_id


     define_upload_image_methods

     def person_data
        return self.person.ajax_attrs(:guest)
     end

     edit_attr_accessible :name, :description, :medium, :image_thumbprint, :featured, :as=>[:admin, :user, nil]
     edit_attr_accessible :person_id, :seo_index, :as=>[:admin, nil]
     ajax_attr_accessible :name, :description, :medium, :image_thumbprint, :featured, :person_id, :as=>[:guest]
     ajax_attr_accessible :person_data, :as=>[nil, :guest, :admin, :user]

    before_validation() do
       postfix = 1
       begin
          new_name = self.name
          if(postfix > 1)
            new_name += "(#{postfix})"
          end
          seo_index = new_name.to_seo
	  postfix = postfix + 1
       end while(GalleryItem.where(:seo_index=>new_name.to_seo, :gallery_id=>self.gallery_id).present?)
       self.name = new_name
       self.seo_index = new_name.to_seo

       self.description ||= ""
       self.medium ||= ""
    end
   end
end
