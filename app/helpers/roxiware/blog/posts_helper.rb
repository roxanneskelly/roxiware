include Roxiware::Helpers
module Roxiware::Blog::PostsHelper
    include ActionView::Helpers::UrlHelper
    include Roxiware::Helpers
  
    def self.display_comments(comment_map, params = {})
	allow_reply = params[:allow_reply] || false
	allow_edit = params[:allow_edit] || false
	comment_id = params[:comment_id] || 0
        comment_date_format = params[:comment_date_format] || "%A, %B %e, %Y %I:%M %p"
	root=comment_map[comment_id] 
	result = ""

	root[:children].each do |child_id|
	    child = comment_map[child_id][:comment]
	    if (allow_edit) || (child.comment_status == "publish")
		result += "<div class='comment' comment_id=#{child.id}>"
		if allow_edit
		  result += <<-HTML
		  <div class="manage_menu manage_comment" id="manage_comment_#{child.id}">
		    <ul><li><div class="manage_button icon-arrow-down-9"></div><ul>
		      <li class="#{ "selected_item" if child.comment_status == "publish" }" ><a class="publish_comment"><div class="checkbox"></div>Publish</a></li>
		      <li class="#{ "selected_item" unless child.comment_status == "publish" }" ><a class="hide_comment"><div class="checkbox"></div>Hide</a></li>
		      <hr/>
		      <li><a class="edit_comment">Edit</a></li>
		      <li><a class="delete_comment">Delete</a></li>
		    </ul></li></ul>
		  </div>
		  HTML
		end
		if(child.person.nil?)
		  comment_author_url = child.comment_author_url
		else
		   comment_author_url = "/people/#{child.person.seo_index}"
		   comment_image_url = child.person.thumbnail_url
		end

		comment_image_url ||= default_image_path(:person, "thumbnail")

		result += "<div class='comment_header'><img src='#{comment_image_url}' class='comment_author_image'/>"
		date = child.comment_date.localtime
		result += "<div class='comment_author_date'>" + date.strftime(comment_date_format)+"</div>"
		if comment_author_url.blank?
		    result += "<div class='comment_author_name'>#{child.comment_author}</div>"
		else
		    result += "<a href='#{child.comment_author_url}' class='comment_author_name'>#{child.comment_author}</a>"
		end
                if allow_edit 
		        result += "<div class='comment_moderate_indicator comment_status_#{child.comment_status}'>Hidden</div>"
		end
		result += "</div>"
	    result += "<div class='comment_content'>"+child.comment_content+"</div>"
	    result += "<div class='comment_footer'>"
            if allow_reply
	       result += "<a id='reply-to-#{child_id}' class='comment_reply'>Reply</a>" 
	    end
	    result += "</div>"
	    result +=  display_comments(comment_map, :allow_reply=>allow_reply, :allow_edit=>allow_edit, :comment_id=>child_id)
	    result += "</div>"
	    end
       end
       result
   end
end
