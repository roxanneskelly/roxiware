module Roxiware
  class Page < ActiveRecord::Base
      include Roxiware::BaseModel
      self.table_name="pages"

     validates_presence_of :page_type, :inclusion => {:in => %w(content mail script widget form)}
     validates_presence_of :page_identifier

      edit_attr_accessible :content, :page_type, :page_identifier, :as=>[:super, :admin, nil]
      ajax_attr_accessible :content, :page_type, :page_identifier
  end
end
