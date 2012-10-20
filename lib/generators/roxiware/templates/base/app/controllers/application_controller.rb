class ApplicationController < ActionController::Base
   include Roxiware::Engine.routes.url_helpers
   include Roxiware::Secret
   include Roxiware::ApplicationControllerHelper

   @@widget_globals = {}
  
   before_filter do |controller|
      populate_application_params(controller)
   end
   before_filter :load_layout
   protect_from_forgery
   layout :resolve_layout

   before_filter :populate_layout_params

   before_filter do
     @current_layout = @@current_layout
     @page_layout = @current_layout.find_page_layout(params[:controller], params[:action])
   end
   rescue_from CanCan::AccessDenied do |exception|
     redirect_to main_app.root_url, :alert => exception.message 
   end

   def current_ability
       @current_ability ||= Ability.new(current_user, params)
   end

end
