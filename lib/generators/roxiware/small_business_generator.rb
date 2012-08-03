module Roxiware
  module Generators
    class SmallBusinessGenerator < Rails::Generators::NamedBase
      include Rails::Generators::ResourceHelpers
      source_root File.expand_path('../templates/small_business', __FILE__)

       desc "Generate an small business roxiware website layout, with authentication, page display"

      def add_base
         generate("roxiware:base", "#{name}  --force --news=true --blog=false --portfolio=true --services=true --events=true --gallery=false --singleperson=false --books=false")
      end

      def add_assets
        directory 'app/assets', 'app/assets'
      end

      def add_routes
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
