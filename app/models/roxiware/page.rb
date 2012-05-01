module Roxiware
  class Page < ActiveRecord::Base
      set_table_name "pages"
      attr_accessible :content, :page_type, :as=>"admin"
      attr_accessible :content, :page_type, :as=>"user"
  end
end
