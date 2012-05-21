module Roxiware
  class Page < ActiveRecord::Base
      include Roxiware::BaseModel
      self.table_name="pages"
      edit_attr_accessible :content, :page_type, :as=>[:admin, nil]
      ajax_attr_accessible :content, :page_type
  end
end
