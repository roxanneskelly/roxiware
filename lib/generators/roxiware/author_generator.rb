module Roxiware
  module Generators
    class AuthorGenerator < Rails::Generators::NamedBase
      include Rails::Generators::ResourceHelpers
      source_root File.expand_path('../templates/author', __FILE__)

       desc "Generate an author roxiware website layout, with authentication, page display"

      def add_base
         generate("roxiware:base", "#{name}  --force --news=false --blog=true --portfolio=false --services=false --events=true --gallery=false --singleperson=true --books=true")
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
