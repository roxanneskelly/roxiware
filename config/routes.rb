Roxiware::Engine.routes.draw do

  constraints :format=>"xml" do 
    get "/sitemap" => "sitemap#index", :format=>"xml" 
  end

  get "/settings" => "settings#show"
  put "/settings" => "settings#update"

  resources :layout, :module=>"layouts" do
    resources :page do
       resources :section do
          resources :widget do
            put "move" => "widget#move", :on=>:member
	  end
       end
    end
  end

  # resources for managing widgets
  resources :widget

  # search
  get "/search" => "search#search"

  get "/account/edit" => "account#edit", :id => 0, :as=>"edit_self"
  put "/account/edit" => "account#update", :id => 0, :as=>"edit_self"
  resources :account
  get "page/:page_type" => "page#show"
  put "page/:page_type" => "page#update"

  post   "asset/:upload_type" => "asset#upload"

  if Roxiware.enable_portfolio
    resources :portfolio_entries
    get "/portfolio" =>"portfolio_entries#index"
  end

  get "/people/" => "people#index"
  get "/people/:seo_index" => "people#show_seo"
  resources :people, :path=>"/person"

  if Roxiware.single_person
    get "/about" => "people#show_seo"
  end

  if Roxiware.enable_services
    get "/service/:service_class" => "services#index"
    get "/service/:service_class/:seo_index" => "services#show_seo"
    resources :services
  end

  if !Roxiware.secret_page.nil?
    get "/secret_page" => "secret_page#index"
    post "/secret_page" => "secret_page#authenticate"
  end

  resources :events

  get "/galleries" => "gallery#index"
  get "/galleries/:gallery_seo_index" => "gallery#show_seo"
  get "/galleries/:gallery_seo_index/:item_seo_index/" => "gallery_items#show_seo"
  resources :gallery do |gallery|
    resources :gallery_item, :path=>:item
  end

    namespace :blog do
      resources :post do
         resources :comment
      end
      get "(:year(/:month(/:day)))" => "post#index_by_date"
      get ":year/:month/:day/:title"=> "post#show_by_title"
      get ":year/:month/:day/:title/edit" => "post#edit_by_title"
      put ":year/:month/:day/:title" => "post#update_by_title"
      delete ":year/:month/:day/:title" => "post#destroy_by_title"
    end
    get ":year/:month/:title" => "blog/post#redirect_by_title", :constraints => {:year => /\d{4}/}

  if Roxiware.enable_news
      get "news/(:year(/:month(/:day)))" => "blog/post#index_by_date"
      get "news/:year/:month/:day/:title"=> "blog/post#show_by_title"
  end
end
