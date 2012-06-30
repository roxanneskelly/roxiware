class ApplicationController < ActionController::Base
   include Roxiware::Engine.routes.url_helpers
   include Roxiware::Secret
   include Roxiware::ApplicationControllerHelper
   before_filter :require_secret
   protect_from_forgery

   before_filter do |controller|
      @left_widgets = []
      @right_widgets = []
      @goodreads = Roxiware::Goodreads::Review.new()
      @goodreads_list = @goodreads.list(:sort=>"random", :page=>1, :per_page=>2, :shelf=>AppConfig::goodreads_favorites_shelf)
      @currently_reading = @goodreads.list(:sort=>"random", :page=>1, :per_page=>1, :shelf=>"currently-reading")
      @right_widgets << "roxiware/shared/currently_reading"
      @right_widgets << "roxiware/shared/book_ads"
   end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to main_app.root_url, :alert => exception.message 
  end

end
