class Roxiware::Service < ActiveRecord::Base
   set_table_name "services"

   validates_presence_of :name
   validates_presence_of :service_class
   validates_uniqueness_of :name, :scope=>:service_class

   before_validation() do
      self.seo_index = self.name.downcase.gsub(/[^a-z0-9]+/i, '-')
   end

   attr_accessible :name, :summary, :description, :service_class, :as=>"admin"
   
   def writeable_attribute_names(current_user)
      role = current_user.role unless current_user.nil?
      case role
      when "admin"
        [:name, :summary, :description, :service_class]
      else
        []
      end
   end
end
