module Roxiware::RoutingHelpers
	def self.applications
	   @@apps
	end
	def self.applications=(new_apps)
	   @@apps = new_apps
	end
        @@apps = [:setup, :page, :account, :design, :people, :galleries, :events, :books, :search, :assets, :settings, :sitemap, :blog_base, :blog, :news, :forum, :contact,:authproxy]

	APP_TYPES = {
	    :author=>[:setup, :page, :account, :design, :people, :events, :books, :search, :assets, :settings, :sitemap, :blog_base, :blog, :contact],
	    :custom=>[:page, :account, :design, :people, :events, :search, :assets, :settings, :sitemap, :blog, :contact, :news, :blog_base]
	}

        APPLICATION_DEPENDENCIES = {
            :comments=>[],
	    :authproxy=>[],
	    :setup=>[:settings],
	    :page=>[:assets],
            :account=>[],
            :design=>[:settings, :assets],
	    :people=>[:assets],
	    :galleries=>[:assets],
	    :events=>[],
	    :books=>[:assets],
	    :search=>[],
	    :assets=>[],
	    :settings=>[],
	    :sitemap=>[],
	    :blog_base=>[:assets, :comments],
	    :blog=>[:blog_base, :assets],
	    :news=>[:blog_base, :assets],
	    :forum=>[:comments],
	    :contact=>[]
	}
end

module ActionDispatch::Routing
    class Mapper
        def roxiware_for(*args)
	    options = Hash[args.extract_options!.collect{|name, value| [name.to_sym, value]}]
	    options[:only] = [options[:only]] unless options[:only].nil? || (options[:only].class == Array)
	    options[:skip] = [options[:skip]] unless options[:skip].nil? || (options[:skip].class == Array)
	    options[:with] = [options[:with]] unless options[:with].nil? || (options[:with].class == Array)

	    options[:only] = options[:only].collect{|app| app.to_sym} if options[:only].present?
	    options[:skip] = options[:skip].collect{|app| app.to_sym} if options[:skip].present?
	    options[:with] = options[:with].collect{|app| app.to_sym} if options[:with].present?

	    applications = Roxiware::RoutingHelpers.applications
	    applications = applications.select{|app| Roxiware::RoutingHelpers::APP_TYPES[options[:application].to_sym].include?(app)} if options[:application].present?
	    applications = applications & options[:only] if options[:only].present?
	    applications = applications - options[:skip] if options[:skip].present?
	    applications = applications + options[:with].select{|app| !applications.include?(app)} if options[:with].present?

	    Roxiware::RoutingHelpers::APPLICATION_DEPENDENCIES.each do |application, dependencies|
	        applications = applications + dependencies.select{|app| !applications.include?(app)} if applications.include?(application)
	    end

	    Roxiware::RoutingHelpers.applications = applications

	    mount Roxiware::Engine => "/", :as=>"roxiware"	    
	end

        def roxiware_setup
	    get "/setup" => "setup#show"
	    put "/setup" => "setup#update"
	    get "/setup/import" => "setup#import"
        end

	def roxiware_page
            resources :page
	end

	def roxiware_account
            scope "/account", :as=>"account" do
	        post "/" => "account#create"
	        get "/edit" => "account#edit", :id => 0, :as=>"edit_self"
	        put "/edit" => "account#update", :id => 0
	        get "/update_password" => "account#edit_password"
	        put "/update_password" => "account#update_password"
                post "/reset_password" => "account#reset_password"
	        get "/sign_in" => "account#show_sign_in"
	        get "/authenticate" => "account#authenticate"
            end
	    get "/admin" => "account#index"
	    resources :account
	end

	def roxiware_design
	    resources :layout, :module=>"layouts" do
	      resources :page do
		 resources :section do
		    resources :widget do
		      put "move" => "widget#move", :on=>:member
		    end
		 end
	      end
	      get "customize" => "layout#customize_form", :on=>:member
	      put "customize" => "layout#customize", :on=>:member
	    end
	end

        def roxiware_people
	    get "/people/" => "people#index"
	    get "/people/:seo_index" => "people#show_seo"
	    get "/biography/" => "people#index"
	    get "/biography/:seo_index" => "people#show_seo"
	    resources :people, :path=>"/person"
	end

        def roxiware_galleries
	    get "/galleries" => "gallery#index"
	    get "/galleries/:gallery_seo_index" => "gallery#show_seo"
	    get "/galleries/:gallery_seo_index/:item_seo_index/" => "gallery_items#show_seo"
	    resources :gallery do |gallery|
	      resources :gallery_item, :path=>:item
	    end
	end

	def roxiware_events
            resources :events
	end

	def roxiware_books
	    resources :books do
	       get 'import', :on=>:collection
	       collection do
		  resources :book_series, :path=>:series do
		     get 'import', :on=>:collection
		     get 'member' => "book_series#member"
		     post 'member' => "book_series#add_book"
		     delete 'member' => "book_series#remove_book"
		  end
	       end
	    end
	end
	
	def roxiware_search
	    # search
	    get "/search" => "search#search"
	end

	def roxiware_assets
	    scope "/asset", :as=>"asset" do
	        post "" => "asset#create"
		put ":asset_url" => "asset#update"
		get "edit" => "asset#edit"
		get ":asset_basename" => "asset#show"
	    end
	end

	def roxiware_settings
            resources :settings do
	       post 'import', :on=>:collection
	    end
	end

	def roxiware_sitemap
	    constraints :format=>"xml" do 
	      get "/sitemap" => "sitemap#index", :format=>"xml" 
	    end
	end

        def roxiware_blog_base
	    namespace :blog do
	      resources :post do
	          post "comment" => "comment#create", :comment_root_type=>"Roxiware::Blog::Post"
	          put "comment/:id" => "comment#update", :comment_root_type=>"Roxiware::Blog::Post"
	          delete "comment/:id" => "comment#destroy", :comment_root_type=>"Roxiware::Blog::Post"
	      end
	    end
	end

        def roxiware_blog
	    namespace :blog do
	      get "(:year(/:month(/:day)))" => "post#index_by_date"
	      get ":year/:month/:day/:title"=> "post#show_by_title"
	      get ":year/:month/:day/:title/edit" => "post#edit_by_title"
	      put ":year/:month/:day/:title" => "post#update_by_title"
	      delete ":year/:month/:day/:title" => "post#destroy_by_title"
            end
	    get ":year/:month/:title" => "blog/post#redirect_by_title", :constraints => {:year => /\d{4}/}
        end

        def roxiware_news
	    scope "/news", :as=>"news" do
	      get "(:year(/:month(/:day)))" => "blog/post#index_by_date", :blog_class=>"news"
	      get ":year/:month/:day/:title"=> "blog/post#show_by_title", :blog_class=>"news"
	    end
	end

        def roxiware_comments
	    resources :comment, :only=>[:create, :update, :destroy], :shallow=>true
	    get "/comment/author" => "comment_author#get"
        end

        def roxiware_forum
	    resources :forum do
	        get ":year/:month/:day/:title"=> "forum#show_topic", :as=>:topic
                post ""=>"forum#create_topic", :as=>:create_topic
                put ":id"=>"forum#update_topic", :as=>:update_topic
                get ":id/edit"=>"forum#edit_topic", :as=>:edit_topic
                get ":id/new"=>"forum#new_topic", :as=>:new_topic
                delete ":id"=>"forum#destroy_topic", :as=>:delete_topic
                put ""=>"forum#update_all", :on=>:collection
	    end
	end

        def roxiware_contact
	    post "/contact" => "contact#create"
	end

	def roxiware_authproxy
  	    get "/account/proxylogin/:provider" => "roxiware/account#proxy_login"
	end
    end
end
