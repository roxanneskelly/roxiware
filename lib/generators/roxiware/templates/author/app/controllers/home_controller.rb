class HomeController < ApplicationController

  def index
      @events = Roxiware::Event.where("start >= :start_date", :start_date=>Time.now.utc.midnight).order("start ASC").limit(3)	
      if !@events.blank?
         @left_widgets << "roxiware/events/events_widget"
      end

      @categories = Hash[Roxiware::Terms::Term.categories().map {|category| [category.id, category]\
}]

      @recent_posts = Roxiware::Blog::Post.published().order("post_date DESC").limit(5).collect{|post| post}
      @post = @recent_posts.shift
      
      @left_widgets << "roxiware/blog/post/recent_posts"
      
 
      @home_box = Roxiware::Page.where(:page_type=>"home_box").first || Roxiware::Page.new({:page_type=>"home_box", :content=>"New Content"}, :as=>"")

  end

end
