class ApplicationController < ActionController::Base
  include Roxiware::Engine.routes.url_helpers
  include Roxiware::Secret

  protect_from_forgery
  before_filter :require_secret

end
