require 'uri'
module Roxiware
  class PortfolioEntry < ActiveRecord::Base
   include Roxiware::BaseModel

    self.table_name = "portfolio_entries"
    validates_presence_of :name
    validates :name, :length =>{:minimum=>2}
    validates_presence_of   :service_class
    validates_uniqueness_of :name, :scope=>:service_class
    validates_uniqueness_of :seo_index, :message=>"Name not sufficiently unique"
    before_validation do
       self.seo_index = self.name.to_seo
       
       if !(self.url.nil? || self.url.empty?) 
         parsed_uri = URI::parse(self.url)
         parsed_uri.scheme = 'http' if parsed_uri.scheme.nil?
         if parsed_uri.host.nil?
           split_path = parsed_uri.path.split
	   parsed_uri.host = split_path[0]
	   parsed_uri.path = "/"+split_path[1..-1].join("/")
         end
         self.url = parsed_uri.to_s
       end
    end

   edit_attr_accessible :name, :service_class, :image_url, :thumbnail_url, :description, :service_class, :url, :blurb, :as=>[:admin, nil]

   ajax_attr_accessible :name, :service_class, :image_url, :thumbnail_url, :description, :service_class, :url, :blurb

  end
end
