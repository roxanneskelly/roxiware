module Roxiware
    class HomeController < ApplicationController
	include Roxiware::ApplicationControllerHelper

        application_name "home"

	def index
	    case(@current_layout.get_param("home_page_type").to_s) 
	        when "content"
		    respond_to do |format|
		       @page = Roxiware::Page.where(:page_type=>"home_page").first || Roxiware::Page.new({:page_type=>"home_page", :content=>""}, :as=>"")
		       format.html { render :template=>"roxiware/page/show"}
		    end

		when "blog_posts"
		    respond_to do |format|
		        @posts = @posts.order("post_date DESC").limit(@blog_posts_per_page+1)
			if(@posts.length > @blog_posts_per_page)
			   @next_page_link = url_for({:page=>1})
			end
			format.html { render :template=>"roxiware/blog/post/index"}
		    end
		when "blog_post"
		    respond_to do |format|
			posts = Roxiware::Blog::Post.visible(nil).order("post_date DESC").limit(2)
			@post = posts.first
			@next_post_link = posts.last.post_link if posts.length > 1
			format.html { render :template=>"roxiware/blog/post/show"}
		    end
	    end
	end
    end
end
