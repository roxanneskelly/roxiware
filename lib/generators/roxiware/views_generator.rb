module Roxiware
  module Generators
    class ViewsGenerator < Rails::Generators::Base
       include Rails::Generators::ResourceHelpers
       source_root File.expand_path("../../../../app/views/roxiware", __FILE__)
       desc "Copy views for customization"
       hide!
       class_option :news, :desc => "Include news", :type => :boolean, :default => true
       class_option :portfolio, :desc => "Include portfolio", :type => :boolean, :default => false
       class_option :services, :desc => "Include services", :type => :boolean, :default => false
       class_option :appearances, :desc => "Include appearances", :type => :boolean, :default => false
       class_option :gallery, :desc => "Include gallery", :type=> :boolean, :default => false
       class_option :secret, :desc => "Include secret", :type=>:boolean, :default=>false

       def copy_views
           views_directory :account
	   views_directory :page
           views_directory :news_item if options.news?
           views_directory :portfolio_entries if options.portfolio?
           views_directory :services if options.services?
           views_directory :appearances if options.appearances?
           views_directory :gallery if options.gallery?
           views_directory :secret_pages if options.gallery?
       end
    end
  end
end
