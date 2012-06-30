require 'set'
require 'sanitize'
module Roxiware
  module BaseModel 

    def self.included(base)
        base.extend(BaseClassMethods)
    end
    
    module BaseClassMethods
        attr_accessor :can_edit_attrs
        attr_accessor :ajax_attrs
        def edit_attr_accessible(*args)
          if args.last.class == Hash
            options = args.pop
          end
          attr_accessible_options = {}
          attr_accessible_options[:as] = options[:as] unless options[:as].nil?

          attr_accessible_options[:as] ||= [nil]

          @can_edit_attrs ||= {}

          options[:as].each do |as_option|
            @can_edit_attrs[as_option.to_s] ||= []
            @can_edit_attrs[as_option.to_s] |= args.collect {|arg| arg.to_s}
          end
          attr_accessible_options = args << {:as=>options[:as].collect {|opt| opt.to_s}}
          send(:attr_accessible, *attr_accessible_options)
        end

        def ajax_attr_accessible(*args)
          if args.last.class == Hash
            options = args.pop
          end
          as_options = options[:as] unless options.nil?
          as_options ||= []

	  if as_options.empty?
	    as_options << :default
	  end
          @ajax_attrs ||= {}
          as_options.each do |as_option|
            @ajax_attrs[as_option.to_s] ||= Set.new([])
            @ajax_attrs[as_option.to_s].merge(args.collect {|arg| arg.to_s})
          end
	end
      end

      def ajax_attrs(role)
	role ||= "default"
	valid_read_keys = Set.new([])

	
	valid_write_keys = self.class.can_edit_attrs[role].clone || Set.new([])
	valid_read_keys |= self.class.ajax_attrs[role] if self.class.ajax_attrs.has_key?(role)
	valid_read_keys |= self.class.ajax_attrs["default"].to_a if self.class.ajax_attrs.has_key?("default")

	# user can of course read keys that they can write
	valid_read_keys |= valid_write_keys

        attrs = {}
        valid_read_keys.each do |key|
	  value = eval("self.#{key}")
	  if value.class == Array
	     attrs[key+"[]"] = value
	     if valid_write_keys.include?(key)
		valid_write_keys.delete(key)
	        valid_write_keys << key+"[]"
	     end
          else
	     attrs[key] = value
	  end
        end
        attrs["can_edit"] = valid_write_keys.to_a
        attrs
      end
  end
end