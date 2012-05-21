module Roxiware
  module Helpers
      def date_field_tag(name, value = nil, options = {})
        text_field_tag(name, value, options.stringify_keys.update("type" => "date"))
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

  end
end