module Roxiware
  class Page < ActiveRecord::Base
      set_table_name "pages"
      attr_accessible :content, :page_type, :as=>"system"
      attr_accessible :content, :page_type, :as=>"admin"
      attr_accessible :content, :as=>"user"

      def writeable_attribute_names(current_user)
        role = current_user.role unless current_user.nil?
        case role
        when "admin"
          [:page_type, :content]
        when "user"
          [:content]
        when "system"
          [:page_type, :content]
        else
          []
        end
   end
  end
end
