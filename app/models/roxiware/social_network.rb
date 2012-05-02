class SocialNetwork < ActiveRecord::Base
    belongs_to :employee, :dependent=>:destroy

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
