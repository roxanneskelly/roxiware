class Roxiware::SocialNetwork < ActiveRecord::Base
    set_table_name "social_networks"
    belongs_to :employee, :dependent=>:destroy
    validates_presence_of :network_type, :inclusion=> {:in =>%w(website twitter facebook google)}
    validates_presence_of :network_link

    attr_accessible :network_type, :network_link, :as=>"user"
    attr_accessible :network_type, :network_link, :as=>"admin"


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
