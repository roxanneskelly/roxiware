module Roxiware
   class Gallery < ActiveRecord::Base
     include Roxiware::BaseModel
     self.table_name="gallery"
     self.default_image = "unknown_picture"


     has_many :gallery_items

     validates :name, :length=>{:minimum=>3,
                                  :to_short => "The name must be at least %{count} characters.",
				  :maximum=>256,
				  :to_long => "The name must be no more than %{count} characters."
				  }
     validates_uniqueness_of :seo_index, :message=>"The name has already been taken"

     validates :image_thumbprint, :length=>{:maximum=>64,
                                 :too_long => "The image thumbprint must be no more than %{count} characters." 
				 }

     define_upload_image_methods

     edit_attr_accessible :name, :description, :image_thumbprint, :as=>[:admin, :user]
     edit_attr_accessible :seo_index, :as=>[nil]

     ajax_attr_accessible :seo_index, :name, :description

    
    before_validation() do
       self.seo_index = self.name.downcase.gsub(/[^a-z0-9]+/i, '-')
    end
   end
end
