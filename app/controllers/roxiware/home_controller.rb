module Roxiware
    class HomeController < ApplicationController
	include Roxiware::ApplicationControllerHelper

        application_name "home"

	def index
	    case(@current_layout.get_param("home_page_type").to_s) 
	        when "content"
		    respond_to do |format|
		       puts "WAS CONTENT"
		       @page = Roxiware::Page.where(:page_type=>"home_page").first || Roxiware::Page.new({:page_type=>"home_page", :content=>""}, :as=>"")
		       format.html { render :template=>"roxiware/page/show"}
		    end

		when "blog"
		    respond_to do |format|
			@posts = Roxiware::Blog::Post.visible(nil).order("post_date DESC").limit(1)
			format.html { render :template=>"roxiware/blog/post/index"}
		    end
	    end
	end
    end
end
