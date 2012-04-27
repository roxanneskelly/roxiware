require 'rails'
require 'devise'
require 'roxiware/version'
require 'roxiware/ability'
module Roxiware
  class Engine < ::Rails::Engine
    engine_name "roxiware"
    isolate_namespace ::Roxiware
  end
end
