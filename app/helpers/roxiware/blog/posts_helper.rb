include ActionView::Helpers::UrlHelper

module Roxiware::Blog::PostsHelper

    def self.display_comments(comment_map, params = {})
      allow_reply = params[:allow_reply] || false
      allow_edit = params[:allow_edit] || false
      comment_id = params[:comment_id] || 0
      root=comment_map[comment_id]
      result = ""
      root[:children].each do |child_id|
        child = comment_map[child_id][:comment]
	if (allow_edit) || (child.comment_status == "publish")
	  result += "<div class='comment'>"
	  if allow_edit
	     result += "<div class='manage_comment'><label for='comment_status'>Publish:</label>"
	     checked = ("publish" == child.comment_status)?"checked":""
	     result += "<input type='checkbox' name='comment_status' value='publish' id='comment_status' #{checked} comment=#{child.id}/>"
	     result += "<div class='comment_delete_button delete_button' id='delete-comment-#{child.post.id}-#{child.id}' >&nbsp;</div></div>"
	  end
	  comment_author_url = nil
	  comment_image_url = nil
	  if(child.person.nil?)
	    comment_author_url = child.comment_author_url
          else
	     comment_author_url = "/people/#{child.person.seo_index}"
	     comment_image_url = child.person.thumbnail_url
          end
	  if !comment_image_url.blank?
	     result += "<img src='#{child.person.thumbnail_url}' class='person_thumbnail'/>"
	  end
          if comment_author_url.blank?
	      result += "<div class='comment_author_name'>#{child.comment_author}</div>"
          else
	      result += "<a href='#{child.comment_author_url}' class='comment_author_name'>#{child.comment_author}</a>"
          end
	  date = child.comment_date.localtime
	  result += "&nbsp;wrote on " + date.strftime("%A, %B %e, %Y %I:%M %p")
	result += "<div class='comment_content'>"+child.comment_content+"</div>"
	if allow_reply
	   result += "<div id='reply-to-#{child_id}' class='comment_reply'>Reply</div>" 
	end
	  result +=  display_comments(comment_map, :allow_reply=>allow_reply, :allow_edit=>allow_edit, :comment_id=>child_id)
	result += "</div>"
	end
     end
     result
   end
end
