require 'uri'

class Roxiware::SocialNetwork < ActiveRecord::Base
    self.table_name="social_networks"
    SOCIAL_NETWORK_TYPES = %w(website twitter facebook google)
    belongs_to :people, :dependent=>:destroy, :autosave=>true
    validates_presence_of :network_type, :inclusion=> {:in => SOCIAL_NETWORK_TYPES}

    attr_accessible :network_type, :network_link, :as=>"user"
    attr_accessible :network_type, :network_link, :as=>nil
    attr_accessible :network_type, :network_link, :as=>"admin"

   before_validation do
     case self.network_type
       when "website"
          if !(self.network_link.blank?)
            parsed_uri = URI::parse(self.network_link)
            parsed_uri.scheme = 'http' if parsed_uri.scheme.nil?
            if parsed_uri.host.nil?
               split_path = parsed_uri.path.split
	       parsed_uri.host = split_path[0]
	       parsed_uri.path = "/"+split_path[1..-1].join("/")
             end
             self.network_link = parsed_uri.to_s
          end
       end
    end


    def writeable_attribute_names(current_user)
       role = current_user.role unless current_user.nil?
       case role
       when "admin"
          [:network_type, :network_link]
       when "user"
          if current_user.id == employee_id
	     [:network_type, :network_link]
          else
             []
          end
       else
          []
       end
    end

    def network_url
       case network_type
       when "website"
          network_link
       when "twitter"
          "http://www.twitter.com/"+network_link
       when "facebook"
          "http://www.facebook.com/"+network_link
       when "google"
          network_link
       else
          nil
       end
    end
end
