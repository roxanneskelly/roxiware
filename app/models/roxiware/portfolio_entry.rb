module Roxiware
  class PortfolioEntry < ActiveRecord::Base
   set_table_name "portfolio_entries"
   validates_presence_of :name
   validates :name, :length =>{:minimum=>2}
   validates_presence_of   :service_class
   validates_uniqueness_of :name, :scope=>:service_class

    before_validation() do
       self.seo_index = self.name.downcase.gsub(/[^a-z0-9]+/i, '-')
    end

   attr_accessible :name, :service_class, :image_url, :thumbnail_url, :description, :service_class, :url, :blurb, :as=>"admin"
   attr_accessible :name, :service_class, :image_url, :thumbnail_url, :description, :service_class, :url, :blurb, :as=>"user"


    def writable_attribute_names(current_user)
       case current_user.role
       when "admin"
          [:name, :service_class, :image_url, :thumbnail_url, :description, :service_class, :blurb,  :url]
       when "user"
          [:name, :service_class, :image_url, :thumbnail_url, :description, :service_class, :blurb,  :url]
       else
          []
       end
    end

  end
end
