class Roxiware::SecretPage < ActiveRecord::Base
   self.table_name="secret_pages"
   validates_presence_of :secret
end
