include Roxiware::Helpers
include ActionView::Helpers::TagHelper
include ActionView::Helpers::UrlHelper
include ActionView::Context
module Roxiware::Blog::PostHelper
    def self.post_header(post, options={})
        header_content = options
	header_format = options[:header_format] || "%{author_image}%{date}%{author_name}%{comments}%{title}"
	date_format = options[:date_format] || "%Y"

        header_content[:categories] = content_tag(:div, :class=>"post_categories") do 
            post.category_ids.collect do |category_id|
	        blog_uri = URI.parse(options[:blog_path] || "/blog")
		blog_uri.query = [blog_uri.query, "category=#{Roxiware::Terms::Term.categories()[category_id].seo_index}"].compact.join("&")
                link_to Roxiware::Terms::Term.categories()[category_id].name, blog_uri.to_s, :class=>"post_category"
            end.join("")
        end

        header_content[:author_image] = (post.person.present? ? tag(:img, :src=>post.person.thumbnail_url, :class=>"post_author_img person_thumbnail") : "")
        header_content[:title] = link_to(post.post_title, post.post_link, :class=>"post_title")
        header_content[:author_name] = (post.person.present? ? link_to(post.person.full_name, "/people/"+post.person.seo_index, :class=>"post_author") : "")
        header_content[:comments] = link_to(post.post_link, :class=>"comments_link") do
            content_tag(:div, post.comment_count, :class=>((post.comment_count == 1) ? "comments_singular comments_count" : "comments_plural comments_count")) +
            (content_tag(:div, post.pending_comment_count, :class=>((post.pending_comment_count == 1) ? "comments_singular pending_comments_count" : "comments_plural pending_comments_count")) if options[:show_pending_comments])
        end
        header_content[:date] = content_tag(:div, post.post_date.localtime.strftime(date_format).html_safe, :class=>"post_date")

        content_tag(:div, ((header_format || "%{author_image}%{date}%{author_name}%{comments}%{title}") % header_content).html_safe, :class=>"post_header")
    end
end