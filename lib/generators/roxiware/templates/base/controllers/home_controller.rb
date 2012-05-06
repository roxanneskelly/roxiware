class HomeController < ApplicationController

  def index
      store_location 
      @news = Roxiware::NewsItem.order("post_date DESC LIMIT 1")
      @portfolio_entries = Roxiware::PortfolioEntry.order("RANDOM()").limit(6).map
      # find a featured blurb
      @featured_blurb = nil
      @portfolio_entries.each() do |portfolio_entry| 
         if !portfolio_entry.blurb.empty?
            @featured_blurb = portfolio_entry
	    @portfolio_entries.delete(portfolio_entry)
            break
         end
      end
      @home_box = Roxiware::Page.where(:page_type=>"home_box").first || Roxiware::Page.new({:page_type=>"home_box", :content=>"New Content"}, :as=>"system")

      logger.debug @home_box
  end

end
