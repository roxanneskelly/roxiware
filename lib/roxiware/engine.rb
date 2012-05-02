require 'rails'
require 'devise'
require 'roxiware/version'
require 'roxiware/ability'
require 'roxiware/jquerypopupform'
require 'roxiware/util'
require 'roxiware/secret'
require 'roxiware/mass_assignment_security'
module Roxiware
  class Engine < ::Rails::Engine
    engine_name "roxiware"
    isolate_namespace ::Roxiware
    initializer  "roxiware.load_helpers" do
       ActiveSupport.on_load(:action_controller) do
           include Roxiware::Util
           include Roxiware::Secret
           include Roxiware::JQueryPopupForm
           before_filter :set_meta_info
           after_filter :store_location
           helper :all
       end
    end
  end
end
