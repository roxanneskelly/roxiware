module Roxiware
    class AuthService < ActiveRecord::Base
        self.table_name=  "auth_services"
        include Roxiware::BaseModel
        belongs_to :user, :autosave=>true

        ALLOWED_PROVIDERS = [:facebook, :google, :twitter, :roxiware]

        edit_attr_accessible :provider, :uid, :user_id, :as=>[:super, :admin, nil]
        ajax_attr_accessible :provider, :uid, :user_id, :as=>[:super, :admin, nil]
    end
end
