module Roxiware
  module Generators
    class BaseGenerator < Rails::Generators::NamedBase
      include Rails::Generators::ResourceHelpers
      source_root File.expand_path('../templates/base', __FILE__)

       desc "Generate a base roxiware website layout, with authentication, page display"

       class_option :news, :desc => "Enable News", :type => :boolean, :default => true
       class_option :blog, :desc => "Enable Blog", :type => :boolean, :default => false
       class_option :portfolio, :desc => "Enable Portfolio", :type => :boolean, :default => false
       class_option :services, :desc => "Enable Services", :type => :boolean, :default => false
       class_option :events, :desc => "Enable Events", :type => :boolean, :default => false
       class_option :gallery, :desc => "Enable Gallery", :type=> :boolean, :default => false
       class_option :secretpage, :desc => "SecretPage", :type=>:string, :default=>""
       class_option :people, :desc => "Enable People", :type=>:boolean, :default=>true
       class_option :singleperson, :desc => "Single Person", :type=>:boolean, :default=>false
       class_option :books, :desc => "Enable Books", :type=>:boolean, :default=>false

      def add_assets
        insert_into_file "app/assets/javascripts/application.js", "//= require roxiware\n", :after => "jquery_ujs\n"
	insert_into_file "app/assets/stylesheets/application.css", " *= require 'roxiware'\n", :after => "require_self\n"
        directory 'app/assets', 'app/assets'
        insert_into_file "config/application.rb", "require 'jquery-rails'\n", :after => "require 'rails/all'\n"
      end

      def add_routes
         route('mount Roxiware::Engine => "/", :as=>"roxiware"')
         route("root :to =>'home#index'")
	 route("get '/contact' => 'roxiware/page#show', :page_type=>'contact'")
         route('devise_for :users, :class_name=>"Roxiware::User", :module=>"devise", :path=>"account", :path_names=>{:sign_in=>"login", :sign_out=>"logout"}, :skip=>:registration')
      end

      def install_migrations
         environment("\n    config.paths['db/migrate'] = Roxiware::Engine.paths['db/migrate'].existent\n")
      end

      def add_seed
         append_to_file "db/seeds.rb", "\nRoxiware::Engine.load_seed\n"
      end

      def application_helpers
        app_controller = <<APPCONTROLLER
   include Roxiware::Engine.routes.url_helpers
   include Roxiware::Secret
   include Roxiware::ApplicationControllerHelper
   before_filter :require_secret

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to main_app.root_url, :alert => exception.message
  end

APPCONTROLLER
          insert_into_file "app/controllers/application_controller.rb", app_controller, :after=>"class ApplicationController < ActionController::Base\n"

       app_helper = <<APPHELPER
   include Roxiware::Engine.routes.url_helpers
   include Roxiware::Secret   
APPHELPER
         insert_into_file "app/helpers/application_helper.rb", app_helper, :after=>"module ApplicationHelper\n"

      end

      def config_environment
        gsub_file "config/environments/development.rb", /(config.active_record.mass_assignment_sanitizer = ).*/, '\1:logger'
        gsub_file "config/environments/test.rb", /(config.active_record.mass_assignment_sanitizer = ).*/, '\1:logger'
      end


      def create_initializer
	data = ""
        initializer("roxiware.rb") do

	   data = <<INITIALIZER
Roxiware.setup do |config| 
  config.enable_news = #{options.news?}
  config.enable_blog = #{options.blog?}
  config.enable_portfolio = #{options.portfolio?}
  config.enable_services = #{options.services?}
  config.enable_events = #{options.events?}
  config.enable_gallery = #{options.gallery?}
  config.secret_page = #{options.secretpage?}
  config.enable_people = #{options.people?}
  config.single_person = #{options.singleperson?}
  config.enable_books = #{options.books?}
  config.gallery_items_per_row = 6
  config.gallery_rows_per_page = 4
end
INITIALIZER

        end
	data
      end

      def copy_config
          directory "config", "config"
      end

      def copy_views
        directory 'app/views', 'app/views'
      end

      def copy_controllers
        directory 'app/controllers', 'app/controllers'
      end

      def copy_helpers
        directory 'app/helpers', 'app/helpers'
      end
    end
  end
end
