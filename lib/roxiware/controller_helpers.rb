module Roxiware
  module ApplicationControllerHelper

    PAGE_LAYOUT = []
    private 
    def after_sign_in_path_for(resource_or_scope)
      "/"
    end
    def after_sign_out_path_for(resource_or_scope)
      "/"
    end

    def current_page?(location_sym)
       if(location_sym.blank?) 
          return true
       end
       location_arr = location_sym.collect {|key, value| [key.to_s, value.to_s]}
       location = Hash[*location_arr.flatten]
       valid_params = params.reject {|key, value| location[key].blank?}
       if(location.eql?(valid_params)) 
	  return true
       end
       return false
    end

    def configure_widgets(widget_map)
         @widgets = {}
         widget_map.each do |position, widgets|
	   widgets.each do |widget|
              if current_page?(widget[:location])
		@widgets[position] ||= []
		new_entry = widget.clone()
	        new_entry[:locals] ||= {}
		enable = widget[:preload].blank?
		enable = self.send(widget[:preload], new_entry[:locals]) unless enable
                @widgets[position] << new_entry if enable
	     end
           end
	end
    end

    def configure_page_layout(page_layout)
      @header_bar_class="header_bar "
      @left_bar_class="left_bar "
      @right_bar_class="right_bar "
      @center_bar_class="center_bar"
      @center_content_class="center_content "
      page_layout.each do |layout|
        if current_page?(layout[:location])
	   @center_bar_class += layout[:center_bar_class] if layout.has_key?(:center_bar_class)
	   @left_bar_class += layout[:left_bar_class] if layout.has_key?(:left_bar_class)
	   @right_bar_class += layout[:right_bar_class] if layout.has_key?(:right_bar_class)
	   @center_content_class += layout[:center_content_class] if layout.has_key?(:center_content_class)
	end
      end      
    end
  end
end
