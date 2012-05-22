Roxiware::Engine.routes.draw do

  get "/account/edit" => "account#edit", :id => 0, :as=>"edit_self"
  put "/account/edit" => "account#update", :id => 0, :as=>"edit_self"
  resources :account
  get "page/:page_type" => "page#show"
  put "page/:page_type" => "page#update"

  post   "asset/:upload_type" => "asset#upload"

  if Roxiware.enable_news
    resources :news_item
    get "news/" =>   "news_item#index"
    get  "news/:year/:month/:day/:seo_index" => "news_items#show_seo"
  end

  if Roxiware.enable_portfolio
    resources :portfolio_entries
    get "/portfolio" =>"portfolio_entries#index"
  end

  if Roxiware.enable_people
    get "/people/" => "people#index"
    get "/people/:seo_index" => "people#show_seo"
    resources :people, :path=>"/person"
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

  if Roxiware.enable_events
    resources :events
  end

  if Roxiware.enable_gallery
    get "/galleries" => "gallery#index"
    get "/galleries/:gallery_seo_index" => "gallery#show_seo"
    get "/galleries/:gallery_seo_index/:item_seo_index/" => "gallery_items#show_seo"
    resources :gallery do |gallery|
      resources :gallery_item, :path=>:item
    end
  end

end
