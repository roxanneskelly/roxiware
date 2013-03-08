require 'uri'
require 'sass'
module Roxiware
   module Layout
     module LayoutBase
        def self.included(base)
        end

	class StyleRenderClass
	   def initialize(params)
              params.each do |key, value|
		 singleton_class.send(:define_method, key) { value }
              end 
           end
 
           def get_binding
              binding
           end
	end

        def style_params
	    puts "STYLE PARAMS for " + self.inspect
	    Hash[self.params.where(:param_class=>:style).collect {|param| [param.name, param.conv_value]}]
        end

        def eval_style(params)
	    style_class = StyleRenderClass.new(params)
	    ERB.new(self.style).result(style_class.get_binding)
	end
     end


     # Layout
     # overall layout
     class Layout < ActiveRecord::Base
	  include Roxiware::BaseModel
          include Roxiware::Layout::LayoutBase
          include Roxiware::Param::ParamClientBase

	  self.table_name= "layouts"

          has_many :term_relationships, :as=>:term_object, :class_name=>"Roxiware::Terms::TermRelationship", :dependent=>:destroy, :autosave=>true
          has_many :terms, :through=>:term_relationships, :class_name=>"Roxiware::Terms::Term"

	  has_many        :params, :class_name=>"Roxiware::Param::Param", :as=>:param_object, :autosave=>true, :dependent=>:destroy
	  has_many        :page_layouts, :autosave=>true, :dependent=>:destroy

          attr_accessor :page_layout_cache
	  @page_layout_cache = nil

	  validates_presence_of :guid, :message=>"The layout guid is missing."
          validates :name, :length=>{:minimum=>5,
                                      :too_short => "The layout name must be at least  %{count} characters.",
				      :maximum=>256,
				      :too_long => "The layout name can be no larger than ${count} characters."
				      }

         validates :description, :length=>{
				      :maximum=>100000,
				      :too_long => "The description can be no larger than ${count} characters."
				      }

	  edit_attr_accessible :description, :style, :setup, :name, :as=>[:super, nil]
	  ajax_attr_accessible :guid, :as=>[:super, :admin, nil]

	  def import(layout_node)
	     self.guid = layout_node["guid"]

             # import layout chooser information
	     self.name = layout_node.find_first("name").content
	     self.description = layout_node.find_first("description").content.strip
             layout_category_nodes = layout_node.find("categories/category")
	     category_strings = layout_category_nodes.collect{|layout_category_node| layout_category_node.content.gsub(/[^a-z0-9]+/i,' ').gsub(/\s+/,' ').strip.capitalize}

	     self.term_ids = Roxiware::Terms::Term.get_or_create(category_strings, Roxiware::Terms::TermTaxonomy::LAYOUT_CATEGORY_NAME).map{|term| term.id}

	     self.style = layout_node.find_first("style").content.strip
	     self.setup = layout_node.find_first("setup").content.strip
	     page_layout_nodes = layout_node.find("pages/page")
	     page_layout_nodes.each do |page_layout_node|
                page_layout = self.page_layouts.build
                page_layout.import(page_layout_node)
	     end
	     params = layout_node.find("params/param")
	     params.each do |param|
               widget_param = self.params.build
               widget_param.import(param, true)
	     end
	     page_layout_nodes = nil
	  end

	  def export(xml_layouts)
	    xml_layouts.layout(:version=>"1.0", :guid=>self.guid) do |xml_layout|
	       xml_layout.name self.name
	       xml_layout.description {|s| s.cdata!(self.description.strip)}
	       xml_layout.setup {|s| s.cdata!((self.setup || "").strip)}
	       xml_layout.categories do |xml_categories|
                  self.terms.each do |term|
		     xml_categories.category do |xml_category|
                        xml_category.category = term.name
                     end
                  end
               end
	       xml_layout.style {|s| s.cdata!(self.style.strip) }
	       xml_layout.params do |xml_params|
	          self.params.each do |param|
		     param.export(xml_params, true)
		  end
	       end
	       xml_layout.pages do |xml_page_layouts|
	         self.page_layouts.each do |page_layout|
		    page_layout.export(xml_page_layouts)
		 end
	       end
	    end
 	  end

          def find_page_layout(current_controller, action)
	       stack = page_layout_stack(current_controller, action)
	       stack[-1] if stack.present?
	  end

	  def page_layout_by_url(layout_id, url_identifier)
	      page_id = URI.decode(url_identifier).split("#")
	      find_page_layout((page_id[0] || ""), (page_id[1] || ""))
	  end



          def page_layout_stack(current_controller, action)
	     controller = current_controller.clone
	     if @page_layout_cache.blank?
	         page_layout_list = self.page_layouts.collect {|page_layout| page_layout}
		 @page_layout_cache=[]
	         @page_layout_cache.concat(self.page_layouts.reject {|page_layout| page_layout.controller.present?})
	         @page_layout_cache.concat(self.page_layouts.reject {|page_layout| page_layout.controller.blank? || page_layout.action.present?})
	         @page_layout_cache.concat(self.page_layouts.reject {|page_layout| page_layout.controller.blank? || page_layout.action.blank?})
	     end

	     result = []
	     @page_layout_cache.each do |page_layout|
	        if(page_layout.is_root? || (page_layout.controller == controller) && (page_layout.action == action))
		   page_layout.refresh_sections_if_needed(result[-1])
		   result <<  page_layout
		end
             end
	     result
	  end

	  def get_styles(layout_scheme, controller, action)
             page_layout = find_page_layout(controller, action)

	     if(layout_scheme != @current_layout_scheme) 
	         @current_layout_scheme = layout_scheme
	         @layout_params_cache = nil
	         @compiled_style_cache = nil
             end
	     
	     if(@layout_params_cache.blank?) 
	        puts "CREATE LAYOUT PARAMS CACHE"
	        @layout_params_cache = get_layout_scheme_params(layout_scheme).merge(style_params)
                @compiled_style_cache = nil
		page_layout.refresh_styles
             end

             if(@compiled_style_cache.nil?)
	        puts "CREATE STYLE PARAMS CACHE"
                 @compiled_style_cache = Sass::Engine.new(eval_style(@layout_params_cache).strip, {
	             :style=>:expanded,
		     :syntax=>:scss,
                     :cache=>false
                 }).render() 
             end
	     @compiled_style_cache + page_layout.get_styles(@layout_params_cache)
	  end

	  def get_layout_scheme_params(layout_scheme)
	     result = {}
	     layout_scheme = get_param("layout_schemes").h[layout_scheme] if get_param("layout_schemes").present?
	     if(layout_scheme.present? && layout_scheme.h["scheme_params"].present?) 
	       result = Hash[layout_scheme.h["scheme_params"].h.collect{|name, param| [name, param.conv_value]}]
	     end
	     result
	  end

	  def resolve_layout_params(layout_scheme, controller, action)
	     if @layout_params.nil?
	        @layout_params = {}
	        self.params.where(:param_class=>:local).each do |param|
	           @layout_params[param.name] = param.conv_value
	        end
             end

	     result = @layout_params.clone
	     page_layout = self.find_page_layout(controller, action)
	     @layout_params.merge(page_layout.resolve_layout_params)
	  end
      end


      # Page Layout
      # Layout of columns, etc. per page
      class PageLayout < ActiveRecord::Base
          include Roxiware::BaseModel
          include Roxiware::Layout::LayoutBase
          include Roxiware::Param::ParamClientBase

          self.table_name= "page_layouts"

	  has_many        :params, :class_name=>"Roxiware::Param::Param", :as=>:param_object, :autosave=>true, :dependent=>:destroy
          has_many        :layout_sections, :autosave=>true, :dependent=>:destroy
          belongs_to      :layout

	  edit_attr_accessible :render_layout, :style, :as=>[:super, nil]
	  edit_attr_accessible :controller, :action, :layout_id, :as=>[nil]
	  ajax_attr_accessible :render_layout, :style, :controller, :action, :layout_id, :as=>[:super, nil]

	  def get_url_identifier
	      URI.encode("#{controller}##{action}", "/")
	  end
	  
	  def set_url_identifier(url_identifier)
	      page_id = URI.decode(url_identifier).split("#")
	      self.controller = page_id[0] || ""
	      self.action = page_id[1] || ""
	  end

	  def is_root?
	     controller.blank? && action.blank?
	  end

          def get_text_name
	      result = ""
              result = self.controller.split("/").last
	      result = "base" if result.blank?
	      result = result
	      result += " "+self.action if self.action.present?
	      result += " page"
	      puts "PAGE LAYOUT NAME " + result
              result.titleize
          end

	  def import(page_layout_node)
	     self.controller    = page_layout_node["controller"]
	     self.action        = page_layout_node["action"]
	     self.render_layout = page_layout_node.find_first("render_layout").content
	     self.style = page_layout_node.find_first("style").content
	     layout_section_nodes = page_layout_node.find("sections/section")
	     layout_section_nodes.each do |layout_section_node|
                layout_section = self.layout_sections.build
                layout_section.import(layout_section_node)
	     end
	     params = page_layout_node.find("params/param")
	     params.each do |param|
               param = self.params.build
               param.import(param, true)
	     end
	     layout_section_nodes = nil
	  end

          def export(xml_page_layouts)
	     xml_page_layouts.page(:controller=>self.controller, :action=>self.action) do |xml_page_layout|
	       xml_page_layout.render_layout self.render_layout
	       xml_page_layout.style {|s| s.cdata!(self.style.strip)}
	       xml_page_layout.params do |xml_params|
	          self.params.each do |param|
		     param.export(xml_params, true)
		  end
	       end
	       xml_page_layout.sections do |xml_layout_sections|
	          self.layout_sections.each do |layout_section|
		     layout_section.export(xml_layout_sections)
		  end
	       end
	     end
          end

          def refresh_styles
	     @compiled_style_cache = nil
	  end
	  
	  def get_styles(params)
	     if(@compiled_style_cache.blank?)
	        new_params = params.merge(style_params)
	        evaled_layout_style = eval_style(new_params) + self.sections.values.collect{|section| section.get_styles(new_params)}.join(" ")
		@compiled_style_cache = Sass::Engine.new(evaled_layout_style, {
			    :style=>:expanded,
			    :syntax=>:scss,
			    :cache=>false
			}).render()
             end
	     @compiled_style_cache
	  end

	  def resolve_layout_params
	     if @layout_params.nil?
	        @layout_params = {}
	        self.params.where(:param_class=>:local).each do |param|
	           @layout_params[param.name] = param.conv_value
	        end
             end
	     @layout_params
          end

	  def reset_sections
	     @sections = nil
	  end

	  def refresh_sections_if_needed(parent_page)
	      if @sections.nil?
	         refresh_sections(parent_page)
	      end
	  end

	  def refresh_sections(parent_page)
	     if parent_page.present?
	        @sections = parent_page.sections.dup
	     else
	        @sections = {}
             end
             layout_sections.each do |layout_section|
		@sections[layout_section.name] = layout_section
	     end
	     
	  end

	  def sections
	     @sections
	  end

	  def section(section_name)
	     @sections[section_name] ||= self.layout_sections.create({:name=>section_name, :style=>""}, :as=>"")
	  end
      end

      # LayoutSection
      # Represents an ordered set of widgets, applied to a 
      # layout section such as the 'left_bar'

      class LayoutSection < ActiveRecord::Base
          include Roxiware::BaseModel
          include Roxiware::Layout::LayoutBase
          include Roxiware::Param::ParamClientBase
          self.table_name= "layout_sections"

	  has_many        :params, :class_name=>"Roxiware::Param::Param", :as=>:param_object, :autosave=>true, :dependent=>:destroy
	  has_many        :widget_instances, :autosave=>true, :dependent=>:destroy
	  belongs_to      :page_layout

	  edit_attr_accessible :style, :as=>[:super, nil]
	  edit_attr_accessible :name, :as=>[nil]
	  ajax_attr_accessible :name, :style, :page_layout_id, :as=>[:super, nil]

	  def get_text_name
              "#{name.split("_").join(" ")} section of #{self.page_layout.get_text_name}".titleize
          end

	  def import(layout_section_node)
	     self.name = layout_section_node["name"]
	     self.style = layout_section_node.find_first("style").content.strip
	     widget_instance_nodes = layout_section_node.find("widget_instances/instance")
	     widget_instance_nodes.each do |widget_instance_node|
                widget_instance = self.widget_instances.build
		widget_instance.import(widget_instance_node)
	     end
	     param_nodes = layout_section_node.find("params/param")
	     if param_nodes.present?
	       param_nodes.each do |param_node|
		 param = self.params.build
		 param.import(param_node, true)
	       end
	     end
	  end

          def export(xml_layout_sections)
	     xml_layout_sections.section(:name=>self.name) do |xml_layout_section|
	       xml_layout_section.style {|s| s.cdata!(self.style.strip)}
	       xml_layout_section.params do |xml_params|
	          self.params.each do |param|
		     param.export(xml_params, true)
		  end
	       end
	       xml_layout_section.widget_instances do |xml_widget_instances|
	          self.widget_instances.each do |widget_instance|
		     widget_instance.export(xml_widget_instances)
		  end
	       end
	     end
          end

	  def get_widget_instances
	     @ordered_instances ||= self.widget_instances.order(:section_order)
	     @ordered_instances
	  end

	  def refresh
	    @ordered_instances = nil
	  end

	  def get_styles(params)
	     new_params = params.merge(style_params)
	     eval_style(new_params) + self.widget_instances.collect{|instance| instance.get_styles(new_params)}.join(" ")
	  end
      end

      # Widget
      # Contains references to basic 'controller' code, style for the widget.  
      class Widget < ActiveRecord::Base
          include Roxiware::BaseModel
          include Roxiware::Layout::LayoutBase
          include Roxiware::Param::ParamClientBase
          self.table_name= "widgets"
	  has_many        :params, :class_name=>"Roxiware::Param::Param", :as=>:param_object, :autosave=>true, :dependent=>:destroy

	  edit_attr_accessible :name, :version, :description, :preload, :render_view, :style, :editform, :as=>[:super, nil]
	  ajax_attr_accessible :guid, :as=>[:super, nil]

          def import(widget_node)
	     self.version = widget_node["version"]
	     self.guid = widget_node["guid"]
	     self.name = widget_node.find_first("name").content
	     self.description = widget_node.find_first("description").content    
	     self.editform = widget_node.find_first("editform").content    
	     self.preload     = widget_node.find_first("preload").content    
	     self.render_view = widget_node.find_first("render_view").content    
	     self.style = widget_node.find_first("style").content    
	     params = widget_node.find("params/param")
	     params.each do |param|
               widget_param = self.params.build
               widget_param.import(param, true)
	     end
	  end

          def export(xml_widgets)
	     xml_widgets.widget(:version=>self.version, :guid=>self.guid) do |xml_widget|
	        xml_widget.name        self.name
	        xml_widget.description {|s| s.cdata!(self.description.strip)}
	        xml_widget.editform {|s| s.cdata!(self.editform.strip)}
	        xml_widget.preload {|s| s.cdata!(self.preload.strip)}
	        xml_widget.render_view {|s| s.cdata!(self.render_view.strip)}
	        xml_widget.style {|s| s.cdata!(self.style.strip)}
		xml_widget.params do |xml_params|
		    self.params.each do |param|
		       param.export(xml_params, true)
		    end
		end
              end
          end
      end

      # WidgetInstance
      # params, layout for the widget within the layout section
      class WidgetInstance < ActiveRecord::Base
          include Roxiware::BaseModel
          include Roxiware::Layout::LayoutBase
          include Roxiware::Param::ParamClientBase
          self.table_name= "widget_instances"

	  has_many   :params, :class_name=>"Roxiware::Param::Param", :as=>:param_object, :autosave=>true, :dependent=>:destroy
	  belongs_to :layout_section

	  edit_attr_accessible :layout_section_id, :section_order, :widget_guid, :as=>[:super, nil]
	  ajax_attr_accessible :layout_section_id, :section_order, :widget_guid, :as=>[:super, nil]

	  def globals
	    @@globals ||= {}
	    @@globals
	  end

	  def clear_globals
	    @@globals = {}
	  end

	  def widget
	     @widget ||= Roxiware::Layout::Widget.where(:guid=>self.widget_guid).first
	     @widget
	  end

	  def widget=(newwidget)
	     @widget = newwidget
	     self.widget_guid = newwidget.guid
	  end

	  def import(widget_instance_node)

             # find widget instance here
	     #
	     self.widget_guid = widget_instance_node["widget_guid"]
	     self.section_order = widget_instance_node["order"]
	     param_nodes = widget_instance_node.find("params/param")
	     param_nodes.each do |param_node|
               param = self.params.build
               param.import(param_node, false)
	     end
	  end

          def export(xml_widget_instances)
	     xml_widget_instances.instance(:order=>self.section_order, :widget_guid=>self.widget_guid) do |xml_widget_instance|
	       xml_widget_instance.params do |xml_params|
	          self.params.each do |param|
		     param.export(xml_params, false)
		  end
	       end
	     end
          end
	  
	  def get_styles(params)
	     self.widget.eval_style(params.merge(style_params))
	  end

	  def get_params
	     if @params.nil?
	        @params = {}
		widget.params.where(:param_class=>:local).each do |param|
                   @params[param.name.to_sym] = param.conv_value
                end
		
	        params.where(:param_class=>:local).each do |param|
                   @params[param.name.to_sym] = param.conv_value
                end
             end
	     @params
          end

	  def get_param_objs
	     if @param_objs.nil?
	        @param_objs = {}
		widget.params.each do |param|
                   @param_objs[param.name.to_sym] =  param
                end
		
	        params.each do |param|
                   @param_objs[param.name.to_sym] =  param
                end
             end
	     @param_objs
          end
      end
   end
end
