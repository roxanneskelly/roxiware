class Roxiware::Employee < ActiveRecord::Base
   has_many :social_networks
   set_table_name "employees"
   validates_presence_of :first_name
   validates :first_name, :length=>{:minimum=>2}
   validates_uniqueness_of :first_name, :scope=>:last_name

    before_validation() do
       full_name = self.first_name
       full_name = (full_name + " "+ self.last_name) unless self.last_name.empty?
       self.seo_index = full_name.downcase.gsub(/[^a-z0-9]+/i, '-')
    end

    attr_accessible :first_name, :last_name, :role, :email, :image_url, :bio, :as=>"admin"

    def writeable_attribute_names(current_user)
       role = current_user.role unless current_user.nil?
       case role
       when "admin"
          [:first_name, :last_name, :role, :email, :image_url, :bio]
       else
          []
       end
    end


end
