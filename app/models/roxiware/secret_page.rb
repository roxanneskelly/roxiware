class Roxiware::SecretPage < ActiveRecord::Base
   set_table_name "secret_pages"
   validates_presence_of :secret
end
