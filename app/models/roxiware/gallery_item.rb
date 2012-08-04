module Roxiware
   class GalleryItem < ActiveRecord::Base
     include Roxiware::BaseModel
     self.table_name="gallery_items"
     self.default_image = "unknown_picture"

     validates_presence_of :person_id
     validates_presence_of :gallery_id
     belongs_to :person
     belongs_to :gallery

     validates :name, :length=>{:minimum=>3,
                                  :to_short => "The name must be at least %{count} characters.",
				  :maximum=>256,
				  :to_long => "The name must be no more than %{count} characters."
				  }
     validates_uniqueness_of :seo_index, :scope=>:gallery_id, :message=>"The name has already been taken"

     validates :description, :length=>{:maximum=>32768,
                                 :too_long => "The description must be no more than %{count} characters." 
				 }

     validates :medium, :length=>{:maximum=>1024,
                                 :too_long => "The medium must be no more than %{count} characters." 
				 }

     validates :image_thumbprint, :length=>{:maximum=>64,
                                 :too_long => "The image thumbprint must be no more than %{count} characters." 
				 }


     before_destroy :destroy_images
     configure_image_handling(%w(small medium huge))

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
