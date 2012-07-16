class ApplicationController < ActionController::Base
   include Roxiware::Engine.routes.url_helpers
   include Roxiware::Secret
   include Roxiware::ApplicationControllerHelper


   before_filter :require_secret
   protect_from_forgery

   
   PAGE_LAYOUT = [{:location=>{:controller=>"home"}, :left_bar_class=>"home_left_bar"}]
   WIDGETS = {}

   # home page layout
   WIDGETS["left"] =  [
      {:location=>{:controller=>"home"}, :view=>"roxiware/page/page_widget", :locals=>{:page_type=>"home_left"}}
   ]
   WIDGETS["left"] << {:location=>{:controller=>"home"}, :view=>"roxiware/events/events_widget", :preload=>"events_widget"} if Roxiware.enable_events
   WIDGETS["left"] << {:location=>{:controller=>"home"}, :view=>"roxiware/blog/post/recent_posts", :preload=>"recent_posts"} if Roxiware.enable_blog
   
   WIDGETS["top"] = [{:location=>{:controller=>"home"}, :view=>"roxiware/page/page_widget", :locals=>{:page_type=>"home"}}]

   if Roxiware.enable_blog
      WIDGETS["left"].concat([
	     {:location=>{:controller=>"roxiware/blog/post"}, :view=>"roxiware/blog/post/calendar_nav", :preload=>"calendar_nav"},
             {:location=>{:controller=>"roxiware/blog/post"}, :view=>"roxiware/blog/post/categories_nav", :preload=>"categories_nav"},
             {:location=>{:controller=>"roxiware/blog/post"}, :view=>"roxiware/blog/post/recent_posts", :preload=>"recent_posts"}])

       WIDGETS["left"] << {:location=>{:controller=>"roxiware/people"}, :view=>"roxiware/blog/post/recent_posts", :preload=>"recent_posts"} if Roxiware.enable_people
   end


   if Roxiware.enable_books
       WIDGETS["right"] = [
           {:location=>{}, :view=>"roxiware/shared/currently_reading", :preload=>"currently_reading"},
           {:location=>{}, :view=>"roxiware/shared/book_ads", :preload=>"book_ads"}]
   end



   before_filter do |controller|
     configure_widgets(WIDGETS) if controller.request.format.html?
     print "gonna configure layout"
     configure_page_layout(PAGE_LAYOUT) if controller.request.format.html?
   end



   def currently_reading
      goodreads = Roxiware::Goodreads::Review.new()
      {
        :currently_reading => goodreads.list(:sort=>"random", :page=>1, :per_page=>1, :shelf=>"currently-reading")
      }
   end
  
   def book_ads
      goodreads = Roxiware::Goodreads::Review.new()
      {
	  :book_ads => goodreads.list(:sort=>"random", :page=>1, :per_page=>2, :shelf=>AppConfig::goodreads_favorites_shelf)
      }
   end

   def recent_posts
     {
        :recent_posts => Roxiware::Blog::Post.published().order("post_date DESC").limit(8).collect{|post| post}
     }
   end

   def categories_nav
     @categories ||= Hash[Roxiware::Terms::Term.categories().map {|category| [category.id, category]  }]

     category_counts = {}
     Roxiware::Terms::TermRelationship.where(:term_id=>@categories.keys, 
	                                     :term_object_id=>Roxiware::Blog::Post.published.map{|post| post.id},
					     :term_object_type=>"Roxiware::Blog::Post").each do |relationship|
       category_counts[relationship.term_id] ||= 0
       category_counts[relationship.term_id] += 1
     end
     {
	 :categories => @categories,
         :category_counts => category_counts
     }
   end

   def calendar_nav     
     calendar_posts = {}
     raw_calendar_posts = Roxiware::Blog::Post.order("post_date DESC").select("id, post_title, post_date, post_link, post_status")

     published_post_ids = []

     raw_calendar_posts.each do |post|
       year = post.post_date.year
       calendar_posts[year] ||= {:count=>0, :unpublished_count=>0, :monthly=>{}}
       calendar_posts[year][:monthly][post.post_date.month] ||= {:count=>0, :unpublished_count=>0, :name=>post.post_date.strftime("%B"), :posts=>[]}
       calendar_posts[year][:monthly][post.post_date.month][:posts] << {:title=>post.post_title, :published=>(post.post_status == "publish"), :link=>post.post_link}
       if post.post_status == "publish"
         calendar_posts[year][:count] += 1
         calendar_posts[year][:monthly][post.post_date.month][:count] += 1
         published_post_ids << post.id
       elsif can? :edit, post
         calendar_posts[year][:unpublished_count] += 1
         calendar_posts[year][:monthly][post.post_date.month][:unpublished_count] += 1
       end
     end
     {:calendar_posts=>calendar_posts}
   end

   def author
     {
       :author => Roxiware::Person.order("id ASC").where(:show_in_directory=>true).limit(1).first
     }
   end
  
   def events_widget
     print "LOADING EVENTS \n\n"
     {
       :events => Roxiware::Event.where("start >= :start_date", :start_date=>Time.now.utc.midnight).order("start ASC").limit(3)
     }
   end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to main_app.root_url, :alert => exception.message 
  end

end
