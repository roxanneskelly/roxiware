module Roxiware
  module ApplicationControllerHelper

    module BaseControllerClassMethods
       def application_name(name = nil)
           @application_name = name if name.present?
	   @application_name
       end
    end

    @@loaded_layouts = {}

    def self.included(base)
       base.extend(BaseControllerClassMethods)
    end

    def application_name
       self.class.application_name
    end

    
    def application_path(params)
        params[:action]
    end

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

    def run_layout_setup(setup_script = nil)
       return unless @current_layout.present?
       run_setup_script = setup_script || @current_layout.setup
       @current_layout.clear_globals
       if (run_setup_script.present?)
          begin
              eval(run_setup_script, binding(), @current_layout.name, 1) 
	  rescue Exception=>e
	      puts "EXCEPTION " + e.message
	      raise e
	  end
       end
    end

    def load_layout
       puts "CURRENT TEMPLATE #{@current_template}"
       puts "CURRENT SCHEME #{@layout_scheme}"
       run_setup = @@loaded_layouts[@current_template].nil?
       @@loaded_layouts[@current_template] ||= Roxiware::Layout::Layout.where(:guid=>@current_template).first
       raise Exception.new("Invalid Layout #{@current_template}") if @@loaded_layouts[@current_template].nil?
       @current_layout = @@loaded_layouts[@current_template]
       run_layout_setup if run_setup
       @page_layout = @@loaded_layouts[@current_template].find_page_layout(params)
       @page_identifier = @page_layout.get_url_identifier
       if(request.format == :html)
         @layout_styles = @@loaded_layouts[@current_template].get_styles(@layout_scheme, params)
       end
    end

    def refresh_layout
       @@loaded_layouts[@current_template] = nil
    end

    def resolve_layout
       # we need to ultimately cache this info in-memory
       if(@page_layout.present? && (request.format.html? || request.format.to_sym.blank?))
          @page_layout.render_layout
       else
          false
       end
    end

    def populate_layout_params
      return if @@loaded_layouts[@current_template].nil?
      @@loaded_layouts[@current_template].resolve_layout_params(@layout_scheme, params).each do |key, value|
        puts "SETTING INSTANCE VARIABLE #{key} to #{value.inspect}"
        self.instance_variable_set("@#{key}".to_sym, value)
      end
    end

    def populate_application_params(controller)
      Roxiware::Param::Param.application_params("system").each do |param|
        controller.instance_variable_set("@#{param.name}".to_sym, param.conv_value)
      end
      if controller.application_name.present?
	Roxiware::Param::Param.application_params(controller.application_name).each do |param|
	  controller.instance_variable_set("@#{param.name}".to_sym, param.conv_value)
	end
      end
      params.each do |key, value|
          if(key.to_s == "preview") 
              preview_settings = value.split(',')
              controller.instance_variable_set("@current_template".to_sym, preview_settings[0])
              controller.instance_variable_set("@layout_scheme".to_sym, preview_settings[1])
          end
      end
    end

    def self.resolve_widget_locals(widget_instance)
       locals = {}
       widget_instance.layout_params.where(:layout_type=>:render).each do |param|
          locals[param.name] = param.value
       end

       eval(widget_instance.widget.preload, binding(), widget_instance.widget.name, 1)
       locals
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
      @layout = {}
      
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

     def flash_widget(locals)
	locals[:flash_content] = nil
	locals[:flash_content] = flash if flash[:notice].present? || flash[:alert].present? || flash[:error].present?
	locals[:flash_content].present?
     end

     def currently_reading(locals)
	goodreads = Roxiware::Goodreads::Review.new()
	locals[:currently_reading] =  goodreads.list(:sort=>"random", :page=>1, :per_page=>1, :shelf=>"currently-reading")
	locals[:currently_reading].present?
     end

     def book_ads(locals)
	goodreads = Roxiware::Goodreads::Review.new()
	locals[:book_ads] = goodreads.list(:sort=>"random", :page=>1, :per_page=>2, :shelf=>AppConfig::goodreads_favorites_shelf)
	locals[:book_ads].present?
     end

     def recent_posts(locals)
       locals[:recent_posts] = Roxiware::Blog::Post.published().order("post_date DESC").limit(8).collect{|post| post}
       locals[:recent_posts].present?
     end

     def categories_nav(locals)
       @categories ||= Hash[Roxiware::Terms::Term.categories().map {|category| [category.id, category]  }]

       category_counts = {}
       Roxiware::Terms::TermRelationship.where(:term_id=>@categories.keys, 
					       :term_object_id=>Roxiware::Blog::Post.published.map{|post| post.id},
					       :term_object_type=>"Roxiware::Blog::Post").each do |relationship|
	 category_counts[relationship.term_id] ||= 0
	 category_counts[relationship.term_id] += 1
       end
       locals[:categories] = @categories
       locals[:category_counts] = category_counts

       category_counts.present?
     end

     def calendar_nav(locals)     
       calendar_posts = {}
       raw_calendar_posts = Roxiware::Blog::Post.order("post_date DESC").select("id, post_title, post_date, post_link, post_status")

       published_post_ids = []

       raw_calendar_posts.each do |post|
	 year = post.post_date.year
	 calendar_posts[year] ||= {:count=>0, :unpublished_count=>0, :monthly=>{}}
	 calendar_posts[year][:monthly][post.post_date.month] ||= {:count=>0, :unpublished_count=>0, :name=>post.post_date.strftime("%B"), :posts=>[]}
	 calendar_posts[year][:monthly][post.post_date.month][:posts] << {:title=>post.post_title, :published=>(post.post_status == "publish"), :link=>post.post_link}
	 if post.post_status == "publish"
	   calendar_posts[year][:count] += 1
	   calendar_posts[year][:monthly][post.post_date.month][:count] += 1
	   published_post_ids << post.id
	 elsif can? :edit, post
	   calendar_posts[year][:unpublished_count] += 1
	   calendar_posts[year][:monthly][post.post_date.month][:unpublished_count] += 1
	 end
       end
       locals[:calendar_posts] = calendar_posts
       return calendar_posts.present?
     end

     def author(locals)
	 locals[:person] =  Roxiware::Person.order("id ASC").where(:show_in_directory=>true).limit(1).first
	 locals[:person].present?
     end

     def events_widget(locals)
       locals[:events] = Roxiware::Event.where("start >= :start_date", :start_date=>Time.now.utc.midnight).order("start ASC").limit(3)
       locals[:events].present? 
     end

     def check_setup
        @setup_step = Roxiware::Param::Param.application_param_val('setup', 'setup_step')
        @setup_type = Roxiware::Param::Param.application_param_val('setup', 'setup_type')
	if(@setup_step != "complete")
	   return false if (params[:controller] == "roxiware/asset")
	   if (params[:controller] == "devise/sessions") 
	      self.class.layout "roxiware/layouts/setup_layout"
	   elsif params[:controller] != "roxiware/setup"
              redirect_to "#{setup_path}?key=#{params[:key]}"
           end
	   return false
 	end
	return true
     end
  end
end
