class ApplicationController < ActionController::Base
   include Roxiware::Engine.routes.url_helpers
   include Roxiware::Secret
   include Roxiware::ApplicationControllerHelper

   before_filter :require_secret
   protect_from_forgery

   PAGE_LAYOUT << {:controller=>"home", :left_bar_class=>"home_left_bar"}

   WIDGETS.concat([
              {:location=>[{:controller=>"home"}], 
	       :left_widgets=>[{:view=>"roxiware/page/page_widget", :locals=>{:page_type=>"home_left"}}],
	       :top_widgets=>[{:view=>"roxiware/page/page_widget", :locals=>{:page_type=>"home"}}]},

              {:location=>[{:controller=>"roxiware/blog/post"}], 
	       :left_widgets=>[{:view=>"roxiware/blog/post/calendar_nav", :locals=>{}},
                               {:view=>"roxiware/blog/post/categories_nav", :locals=>{}}]
	       }])

   if Roxiware.enable_events
       WIDGETS <<  {:location=>[{:controller=>"roxiware/blog/post"}, 
                                {:controller=>"home"}, 
                                {:controller=>"roxiware/people"}], 
	            :left_widgets=>[{:view=>"roxiware/events/events_widget"}]}
   end
   
   if Roxiware.enable_books
       WIDGETS << {:location=>[{}],
        :right_widgets=>[{:view=>"roxiware/shared/currently_reading"}, {:view=>"roxiware/shared/book_ads"}]}
   end

   before_filter :configure_widget_layout
   before_filter :configure_page_layout

   if Roxiware.enable_blog
       WIDGETS << {:location=>[{:controller=>"roxiware/blog/post"}, {:controller=>"home"}, {:controller=>"roxiware/people"}], 
        :left_widgets=>[{:view=>"roxiware/blog/post/recent_posts"}],
        :right_widgets=>[]}
   end
   before_filter do |controller|
      if params[:format].nil? || params[:format] == "html"
	if Roxiware.enable_books
            @goodreads = Roxiware::Goodreads::Review.new()
	    @goodreads_list = @goodreads.list(:sort=>"random", :page=>1, :per_page=>2, :shelf=>AppConfig::goodreads_favorites_shelf)
	    @currently_reading = @goodreads.list(:sort=>"random", :page=>1, :per_page=>1, :shelf=>"currently-reading")
        end

        if Roxiware.enable_blog
	   @recent_posts = Roxiware::Blog::Post.published().order("post_date DESC").limit(8).collect{|post| post}
           @categories = Hash[Roxiware::Terms::Term.categories().map {|category| [category.id, category]  }]
	   @author = Roxiware::Person.order("id ASC").where(:show_in_directory=>true).limit(1).first
        end

        if Roxiware.enable_events
           @events = Roxiware::Event.where("start >= :start_date", :start_date=>Time.now.utc.midnight).order("start ASC").limit(3)
        end
     end
   end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to main_app.root_url, :alert => exception.message 
  end

end
