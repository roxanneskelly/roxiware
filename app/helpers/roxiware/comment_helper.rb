include Roxiware::Helpers
include ActionView::Helpers::TagHelper
include ActionView::Helpers::UrlHelper
include ActionView::Context
module Roxiware::CommentHelper
    include Roxiware::Helpers
    def self.display_comments(comment_map, params = {})
	allow_reply = params[:allow_reply] || false
	allow_edit = params[:allow_edit] || false
	comment_id = params[:comment_id] || 0
        comment_date_format = params[:comment_date_format] || "%A, %B %e, %Y %I:%M %p"
	comment_header_format = params[:comment_header_format] || "%{author_image}%{date}%{author_name}%{moderate_indicator}" 
	root=comment_map[comment_id]
	

	root[:children].collect do |child_id|
            result = "".html_safe
	    child = comment_map[child_id][:comment]
	    next unless (allow_edit) || (child.comment_status == "publish")
	    comment_result = "".html_safe
	    comment_result += content_tag(:a, "", :id=>child_id)
            comment_result +=  content_tag(:div, :class=>"manage_menu manage_comment", :id=>"manage_comment_#{child.id}") do 
                content_tag(:ul) do 
		    content_tag(:li) do 
		        content_tag(:div, "", :class=>"manage_button icon-arrow-down-9") +  
			content_tag(:ul) do 
			    content_tag(:li, :class=>((child.comment_status == "publish") ? "selected_item" : "")) do 
				content_tag(:a, content_tag(:div, "", :class=>"checkbox") + "Publish", :class=>"publish_comment")
			    end + 
			    content_tag(:li, :class=>((child.comment_status != "publish") ? "selected_item" : "")) do 
				content_tag(:a, content_tag(:div, "", :class=>"checkbox") + "Hide", :class=>"hide_comment")
			    end + 
			    tag(:hr) + 
			    content_tag(:li) do
				content_tag(:a, "Delete", :class=>"delete_comment")
			    end
			end
                    end
                end
            end if allow_edit
	    header_content = {}
	    header_content[:author_image] = ""
	    if child.comment_author.present?
	        if child.comment_author.url.present?
		    header_content[:author_image] = link_to(tag(:img, :src=>child.comment_author.get_thumbnail_url, :class=>"comment_author_image"), child.comment_author.url, :target=>"_blank") 
		    header_content[:author_name] = link_to(child.comment_author.name, child.comment_author.url, :class=>"comment_author_name", :target=>"_blank")
		else
		    header_content[:author_image] = tag(:img, :src=>child.comment_author.get_thumbnail_url, :class=>"comment_author_image")
		    header_content[:author_name] = content_tag(:div, child.comment_author.name, :class=>"comment_author_name")
		end
            else
                header_content[:author_image] = ""
	        header_content[:author_name] = "Unknown"
            end
	    header_content[:date] = content_tag(:div, child.comment_date.localtime.strftime(comment_date_format), :class=>"comment_date")
	    header_content[:moderate_indicator] = allow_edit ? content_tag(:div, "Hidden", :class=>"comment_moderate_indicator comment_status_#{child.comment_status}") : ""

            comment_result += content_tag(:div, 
	         (comment_header_format % header_content).html_safe, 
		 :class=>"comment_header", 
		 :comment_author_auth=> (child.comment_author.present? ? child.comment_author.authtype : "unknown"))
	    comment_result += content_tag(:div, child.comment_content.html_safe, :class=>"comment_content")
	    comment_result += content_tag(:div, :class=>"comment_footer") do 
	        allow_reply ? content_tag(:a, "", :class=>"comment_reply", :id=>"reply-to-#{child_id}") : ""
            end
	    result += content_tag(:div, comment_result, :class=>"comment_content_wrapper")
           result +=  display_comments(comment_map, params.merge({:comment_id=>child_id}))
	   read_class = comment_map[child_id][:unread] ? "unread_comment" : "read_comment"
           content_tag(:div, result, :class=>"comment #{read_class}", :comment_id=>child.id)
        end.join("").html_safe
    end
end
