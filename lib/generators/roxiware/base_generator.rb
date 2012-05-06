module Roxiware
  module Generators
    class BaseGenerator < Rails::Generators::NamedBase
      include Rails::Generators::ResourceHelpers
      source_root File.expand_path('../templates/base', __FILE__)

      desc "Generate a base roxiware website layout, with authentication, page display"

       class_option :news, :desc => "Include news", :type => :boolean, :default => true
       class_option :portfolio, :desc => "Include portfolio", :type => :boolean, :default => false
       class_option :services, :desc => "Include services", :type => :boolean, :default => false
       class_option :appearances, :desc => "Include appearances", :type => :boolean, :default => false
       class_option :gallery, :desc => "Include gallery", :type=> :boolean, :default => false
       class_option :employees, :desc => "Include employees", :type=>:boolean, :default=>false

      def add_assets
        insert_into_file "app/assets/javascripts/application.js", "//= require roxiware\n", :after => "jquery_ujs\n"
        directory 'assets', 'app/assets'
      end

      def add_routes
         route('mount Roxiware::Engine => "/", :as=>"roxiware"')
         route("root :to =>'home#index'")
      end

      def install_migrations
         environment("\nconfig.paths['db/migrate'] = Roxiware::Engine.paths['db/migrate'].existent\n")
      end

      def create_initializer
	data = ""
        initializer("roxiware.rb") do

	   data = <<INITIALIZER
Roxiware.setup do |config| 
  config.include_news = #{options.news?}
  config.include_portfolio = #{options.portfolio?}
  config.include_services = #{options.services?}
  config.include_appearances = #{options.appearances?}
  config.include_gallery = #{options.gallery?}
  config.secret_page = nil
  config.include_employees = #{options.employees?}
end
INITIALIZER

        end
	data
      end

      def copy_config
          copy_file "config.yml", "config/config.yml"
      end

      def copy_views
        directory 'views', 'app/views'
      end

      def copy_controllers
        directory 'controllers', 'app/controllers'
      end

      def copy_helpers
        directory 'helpers', 'app/helpers'
      end
    end
  end
end
