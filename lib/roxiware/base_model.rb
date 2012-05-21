require 'set'
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
	  logger.debug("as options " + as_options.to_json)
          @ajax_attrs ||= {}
          as_options.each do |as_option|
            @ajax_attrs[as_option.to_s] ||= []
            @ajax_attrs[as_option.to_s] |= args.collect {|arg| arg.to_s}
          end
	end
      end

      def ajax_attrs(role)
        print "role is #{role}\n"
	role ||= "default"
	valid_read_keys = []
        print "role is #{role}\n"
	
	valid_write_keys = self.class.can_edit_attrs[role] || []
	valid_read_keys |= self.class.ajax_attrs[role] if self.class.ajax_attrs.has_key?(role)
	valid_read_keys |= self.class.ajax_attrs["default"] if self.class.ajax_attrs.has_key?("default")

	# user can of course read keys that they can write
	valid_read_keys |= valid_write_keys

        attrs = {}
        valid_read_keys.each do |key|
          attrs[key] = eval("self.#{key}")
        end
        attrs["can_edit"] = valid_write_keys
	print "ajax attrs according to #{role}\n"
	print attrs.to_json + "\n\n"
        attrs
      end
  end
end