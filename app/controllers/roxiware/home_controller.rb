module Roxiware
    class HomeController < ApplicationController
        include Roxiware::ApplicationControllerHelper
        application_name "home"

        def index
            case(@current_layout.get_param("home_page_type").to_s)
            when "none"
                respond_to do |format|
                    format.html { render :template=>"roxiware/home/none"}
                end
            when "content"
                # Show the content
                respond_to do |format|
                    @page = Roxiware::Page.where(:page_type=>"content", :page_identifier=>"home_page").first || Roxiware::Page.new({:page_type=>"content", :page_identifier=>"home_page", :content=>""}, :as=>"")
                    @page_images = [@page.content[/img.*?src="(.*?)"/i,1]]
                    format.html { render :template=>"roxiware/page/show"}
                end

            when "blog_posts"
                # Show the first page of blog posts
                respond_to do |format|
                    num_posts = @posts_per_page || Roxiware::Param::Param.application_param_val("blog", "blog_posts_per_page")
                    @posts = Roxiware::Blog::Post.where(:post_status=>"publish").order("post_date DESC").limit(num_posts+1)
                    post_count = Roxiware::Blog::Post.where(:post_status=>"publish").count
                    @page_images = [@posts.first.post_image] if @posts.first.present?
                    @blog_url = @posts.first.post_link if @posts.first.present?
                    @blog_class="blog"
                    @page_images = [@posts.first.post_image] if @posts.first.present?
                    @og_url = @posts.first.post_link if @posts.first.present?
                    @og_video_url = @posts.first.post_video if @posts.first.present? && @posts.first.post_video.present?
                    @page = 1
                    @link_params = {:controller=>"roxiware/blog/post", :action=>"index_by_date"}
                    if(@posts.length == num_posts+1)
                        @next_page_link = send("#{@blog_class}_path")+"?page=2"
                        @posts.pop
                    end
                    @num_pages = (post_count.to_f/num_posts.to_f).ceil.to_i
                    format.html { render :template=>"roxiware/blog/post/index"}
                end
            when "first_blog_post_excerpt"
                # excerpt of first blog post
                respond_to do |format|
                    @posts = Roxiware::Blog::Post.where(:post_status=>"publish").order("post_date DESC").limit(1)
                    @page_images = [@posts.first.post_image] if @posts.first.present?
                    @og_url = @posts.first.post_link if @posts.first.present?
                    @og_video_url = @posts.first.post_video if @posts.first.present? && @posts.first.post_video.present?
                    @blog_class="blog"
                    @next_page_link = send("#{@blog_class}_path")
                    @content_path = @posts.first.post_link if @posts.first.present?
                    format.html { render :template=>"roxiware/blog/post/index"}
                end
            when "first_blog_post_with_comments"
                # entire first blog post with comments
                respond_to do |format|
                    posts = Roxiware::Blog::Post.where(:post_status=>"publish").order("post_date DESC").limit(2)
                    @post = posts.first
                    @blog_class="blog"
                    if @post.present?
                        @content_path = @post.post_link
                        @page_images = [@post.post_image]
                        @og_url = @post.post_link
                        @og_video_url = @post.post_video if @post.present? && @post.post_video.present?
                        @next_post_link = posts.last.post_link if posts.length > 1
                        comments = @post.comments.visible(current_user).order("comment_date DESC")

                        # create comment hierarchy
                        @show_comments = true
                        @comments = {}
                        comments.each do |comment|
                            @comments[comment.parent_id] ||= {:children=>[]}
                            @comments[comment.id] ||= {:children=>[]}
                            @comments[comment.parent_id][:children] << comment.id
                            @comments[comment.id][:comment] = comment
                        end
                        format.html { render :template=>"roxiware/blog/post/show"}
                    else
                        format.html { render :template=>"roxiware/home/blankblog"}
                    end
                end
            when "first_blog_post"
                # entire first blog post with comments
                respond_to do |format|
                    posts = Roxiware::Blog::Post.where(:post_status=>"publish").order("post_date DESC").limit(2)
                    @post = posts.first
                    @blog_class="blog"
                    if @post.present?
                        @page_images = [@post.post_image]
                        @og_url = @post.post_link
                        @og_video_url = @post.post_video if @post.present? && @post.post_video.present?
                        @next_post_link = posts.last.post_link if posts.length > 1
                        format.html { render :template=>"roxiware/blog/post/show"}
                    else
                        format.html { render :template=>"roxiware/home/blankblog"}
                    end
                end
            end
        end
    end
end
