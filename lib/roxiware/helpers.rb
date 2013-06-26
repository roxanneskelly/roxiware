require 'uri'
module Roxiware
  module Helpers
      def date_field_tag(name, value = nil, options = {})
        text_field_tag(name, value, options.stringify_keys.update("type" => "date"))
      end

      def param_field(field_group, param, options={})
            title = param.param_description.description
            result = "<div style='display:inline' class='param-field param-field-#{param.param_description.field_type}'>"
	    label = field_group.label(param.name.to_sym, param.name.titleize, {:title=>title})
	    options[:title] = title
            case param.param_description.field_type
               when "color"
                 result += label + field_group.text_field(param.name.to_sym, options.merge({:type=>"text", :alt_type=>"color", :watermark=>"none", :value=>param.value, :param_name=>param.name}))
	       # number field doesn't grab focus as far as 'backspace', which affects jstree
               # when "integer"
               #  result += label + field_group.number_field(param.name.to_sym, options.merge({:value=>param.value, :param_name=>param.name}))
               when "string"
                 result += label + field_group.text_field(param.name.to_sym, options.merge({:value=>param.value, :param_name=>param.name}))
               when "select"
		 select_options = param.param_description.meta.split(",").collect{|option| option.split(":")}
                 result += label + field_group.select(param.name.to_sym, select_options, options.merge({:selected=>param.value, :param_name=>param.name}))
               when "float"
                 result += label + field_group.number_field(param.name.to_sym, options.merge({:value=>param.value, :param_name=>param.name}))
	       when "bool"
                 result += field_group.check_box(param.name.to_sym, options.merge({:checked=>param.conv_value, :param_name=>param.name}), "true", "false") + content_tag(:span, "", :class=>"control-icon checkbox-icon")+label
	       when "text"
                 result += label + text_area_tag(param.name.to_sym, param.to_s, options.merge({:param_name=>param.name}))
               else
                 result += label + field_group.text_field(param.name.to_sym, options.merge({:value=>param.value, :param_name=>param.name}))
             end
	     result += "</div><br/>"
	     raw result
      end

      def param_fields(field_group, params, options = {})
          raw params.collect {|param| param_field(field_group, param, options)}.join(" ")
      end

      def flash_from_object_errors(object, *params)
        error_result = ""
	object.errors.each do |attribute, error_array|
          logger.debug("Flash result " + attribute.to_s + ":" + error_array.to_json)
	  error_result += ", " unless error_result.blank?
	  error_result += attribute.to_s + " - " + error_array.to_s
	end
	error_result
      end

      def cdn_asset(asset_path)
          URI::join(AppConfig.cdn_url, asset_path).to_s
      end


      def cdn_icon(icon_name, theme, scheme)
          URI::join(AppConfig.cdn_url, "themes/#{theme}/#{scheme}/icons/#{icon_name}.png").to_s
      end

      def default_image_path(resource_type, image_size)
         case resource_type
         when :person
             ActionController::Base.helpers.image_path("unknown_person_#{image_size}.png")
         when :book
             ActionController::Base.helpers.image_path("unknown_book_#{image_size}.png")
         else
             ActionController::Base.helpers.image_path("unknown_image_#{image_size}.png")
         end
      end

      def mobile_device?
	if session[:mobile_param]
	  session[:mobile_param] == "1"
	else
	  request.user_agent =~ /Mobile|webOS/
	end
      end

      def social_network_url(network_type, network_id)
	 case network_type
	 when "website"
	    network_id
	 when "twitter"
	    "http://www.twitter.com/"+network_id
	 when "facebook"
	    "http://www.facebook.com/"+network_id
	 when "google"
	    network_id
         when "tumblr"
            "http://#{network_id}.tumblr.com/"
         when "foursquare"
            "http://foursquare.com/#{network_id}"
         when "foursquare"
            "http://foursquare.com/#{network_id}"
         when "goodreads"
             network_id
	 when "youtube"
             "http://www.youtube.com/#{network_id}"
	 else
	    nil
	 end
      end
  end
end