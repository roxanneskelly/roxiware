module Roxiware
  module Helpers
      def date_field_tag(name, value = nil, options = {})
        text_field_tag(name, value, options.stringify_keys.update("type" => "date"))
      end

      def param_field(field_group, param, options={})
            result = "<div title='#{h param.param_description.description}' style='display:inline'>"
	    result += field_group.label(param.name.to_sym, param.name.titleize)
            case param.param_description.field_type
               when "color"
                 result += field_group.text_field(param.name.to_sym, options.merge({:type=>"color", :value=>param.value}))
	       # number field doesn't grab focus as far as 'backspace', which affects jstree
               # when "integer"
               #  result += field_group.number_field(param.name.to_sym, options.merge({:value=>param.value}))
               when "string"
                 result += field_group.text_field(param.name.to_sym, options.merge({:value=>param.value}))
               when "select"
		 select_options = param.param_description.meta.split(",").collect{|option| option.split(":")}
                 result += field_group.select(param.name.to_sym, select_options, options.merge({:selected=>param.value}))
               when "float"
                 result += field_group.number_field(param.name.to_sym, options.merge({:value=>param.value}))
	       when "bool"
                 result += field_group.check_box(param.name.to_sym, options.merge({:checked=>param.conv_value}), "true", "false")
               else
                 result += field_group.text_field(param.name.to_sym, options.merge({:value=>param.value}))
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
  end
end