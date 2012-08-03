class ApplicationController < ActionController::Base
   include Roxiware::Engine.routes.url_helpers
   include Roxiware::Secret
   include Roxiware::ApplicationControllerHelper


   before_filter :require_secret
   protect_from_forgery

   
   PAGE_LAYOUT = [{:location=>{:controller=>"home"}, :left_bar_class=>"home_left_bar"}]
   WIDGETS = {}

   WIDGETS["header_bar"] = [
      {:location=>{}, :view=>"roxiware/shared/flash", :locals=>{}, :preload=>"flash_widget"}
   ]

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
     configure_page_layout(PAGE_LAYOUT) if controller.request.format.html?
   end

   def flash_widget(locals)
      locals[:flash_content] = nil
      locals[:flash_content] = flash if flash[:notice].present? || flash[:alert].present? || flash[:error].present?
      locals[:flash_content].present?
   end

   def currently_reading(locals)
      goodreads = Roxiware::Goodreads::Review.new()
      locals[:currently_reading] =  goodreads.list(:sort=>"random", :page=>1, :per_page=>1, :shelf=>"currently-reading")
      locals[:currently_reading].present?
   end
  
   def book_ads(locals)
      goodreads = Roxiware::Goodreads::Review.new()
      locals[:book_ads] = goodreads.list(:sort=>"random", :page=>1, :per_page=>2, :shelf=>AppConfig::goodreads_favorites_shelf)
      locals[:book_ads].present?
   end

   def recent_posts(locals)
     locals[:recent_posts] = Roxiware::Blog::Post.published().order("post_date DESC").limit(8).collect{|post| post}
     locals[:recent_posts].present?
   end

   def categories_nav(locals)
     @categories ||= Hash[Roxiware::Terms::Term.categories().map {|category| [category.id, category]  }]

     category_counts = {}
     Roxiware::Terms::TermRelationship.where(:term_id=>@categories.keys, 
	                                     :term_object_id=>Roxiware::Blog::Post.published.map{|post| post.id},
					     :term_object_type=>"Roxiware::Blog::Post").each do |relationship|
       category_counts[relationship.term_id] ||= 0
       category_counts[relationship.term_id] += 1
     end
     locals[:categories] = @categories
     locals[:category_counts] = category_counts

     category_counts.present?
   end

   def calendar_nav(locals)     
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
     locals[:calendar_posts] = calendar_posts
     return calendar_posts.present?
   end

   def author(locals)
       locals[:person] =  Roxiware::Person.order("id ASC").where(:show_in_directory=>true).limit(1).first
       locals[:person].present?
   end
  
   def events_widget(locals)
     locals[:events] = Roxiware::Event.where("start >= :start_date", :start_date=>Time.now.utc.midnight).order("start ASC").limit(3)
     locals[:events].present? 
   end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to main_app.root_url, :alert => exception.message 
  end

end
