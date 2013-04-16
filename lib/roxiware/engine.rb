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
require 'roxiware/sanitizer'
require 'recaptcha/rails'
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
           include Roxiware::Sanitizer
           after_filter :store_location
           helper :all
       end
    end
    def root
       File.expand_path(__FILE__ + "/../../..");
    end
  end
end
