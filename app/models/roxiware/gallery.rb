module Roxiware
   class Gallery < ActiveRecord::Base
     include Roxiware::BaseModel
     self.table_name="gallery"
     self.default_image = "unknown_picture"


     has_many :gallery_items
     validates_presence_of :name
     validates_uniqueness_of :name
     validates_uniqueness_of :seo_index, :message=>"Name not sufficiently unique"
     validates_presence_of :seo_index

     define_upload_image_methods

     edit_attr_accessible :name, :description, :image_thumbprint, :as=>[:admin, :user]
     edit_attr_accessible :seo_index, :as=>[nil]

     ajax_attr_accessible :seo_index, :name, :description

    
    before_validation() do
       self.seo_index = self.name.downcase.gsub(/[^a-z0-9]+/i, '-')
    end
   end
end
