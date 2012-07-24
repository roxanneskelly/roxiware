require 'rails'
require 'devise'
require 'cancan'
require 'httparty'
require 'roxiware/version'
require 'roxiware/ability'
require 'roxiware/jquerypopupform'
require 'roxiware/util'
require 'roxiware/secret'
require 'roxiware/helpers'
require 'roxiware/mass_assignment_security'
require 'roxiware/controller_helpers'
require 'roxiware/base_model'
require 'roxiware/goodreads'
require 'roxiware/seo_string'
require 'roxiware/image_helpers'
module Roxiware
  class Engine < ::Rails::Engine
    engine_name "roxiware"
    isolate_namespace ::Roxiware
    initializer  "roxiware.load_helpers" do
       ActiveSupport.on_load(:action_controller) do
           include Roxiware::Util
           include Roxiware::Secret
           include Roxiware::ImageHelpers
           include Roxiware::JQueryPopupForm
           include Roxiware::Helpers
           before_filter :set_meta_info
           after_filter :store_location
           helper :all
       end
    end
  end
end
