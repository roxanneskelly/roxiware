class Roxiware::Service < ActiveRecord::Base
   include Roxiware::BaseModel

   self.table_name="services"

   validates_presence_of :name
   validates_presence_of :service_class
   validates_uniqueness_of :name, :scope=>:service_class

   before_validation() do
      self.seo_index = self.name.downcase.gsub(/[^a-z0-9]+/i, '-')
   end

   edit_attr_accessible :name, :summary, :description, :as=>[:admin, nil]
   edit_attr_accessible :service_class, :as=>[nil]
   ajax_attr_accessible :name, :summary, :description
   ajax_attr_accessible :service_class, :as=>[nil]
end
