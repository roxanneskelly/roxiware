module Roxiware
   class Gallery < ActiveRecord::Base
     include Roxiware::BaseModel
     self.table_name="gallery"
     has_many :gallery_items
     validates_presence_of :name
     validates_uniqueness_of :name
     validates_uniqueness_of :seo_index, :message=>"Name not sufficiently unique"
     validates_presence_of :seo_index
     validates_presence_of :thumbnail_url

     edit_attr_accessible :name, :description, :image_url, :thumbnail_url, :as=>[:admin, :user]
     edit_attr_accessible :seo_index, :as=>[nil]

     ajax_attr_accessible :seo_index, :name, :description, :image_url, :thumbnail_url
    
    before_validation() do
       self.seo_index = self.name.downcase.gsub(/[^a-z0-9]+/i, '-')
    end
   end
end
