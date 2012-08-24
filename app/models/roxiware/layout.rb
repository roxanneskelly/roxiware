module Roxiware
   module Layout
     # Layout
     # overall layout
     class Layout < ActiveRecord::Base
	  include Roxiware::BaseModel
	  self.table_name= "layouts"

	  has_many        :params, :class_name=>"Roxiware::Param::Param", :as=>:param_object, :autosave=>true, :dependent=>:destroy
	  has_many        :page_layouts, :autosave=>true, :dependent=>:destroy

	  attr_accessible :name               # name of the layout
	  attr_accessible :description        # description of the layout
	  attr_accessible :style              # general style for this layout
	  attr_accessible :guid               # unique id for this layout
          attr_accessor :page_layout_cache
	  @page_layout_cache = nil

	  def import(layout_node)
	     self.guid = layout_node["guid"]
	     self.name = layout_node.find_first("name").content
	     self.description = layout_node.find_first("description").content
	     self.style = layout_node.find_first("style").content
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
	       xml_layout.description self.description
	       xml_layout.style {|s| s.cdata!(self.style) }
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

          def find_page_layout(controller, action)
	     if @page_layout_cache.blank?
	         page_layout_list = self.page_layouts.collect {|page_layout| page_layout}
	         @page_layout_cache = self.page_layouts.reject {|page_layout| page_layout.controller.blank? || page_layout.action.blank?}
	         @page_layout_cache.concat(self.page_layouts.reject {|page_layout| page_layout.controller.blank? || page_layout.action.present?})
	         @page_layout_cache.concat(self.page_layouts.reject {|page_layout| page_layout.controller.present?})
	     end


	     @page_layout_cache.each do |page_layout|
	        if((page_layout.controller == controller) || page_layout.controller.blank?)
		   if ((page_layout.action == action) || page_layout.action.blank?)
		      return page_layout
		   end
		end
             end
	     nil
	  end

	  def get_styles(controller, action)
	     @style_params ||= self.params.where(:param_class=>:style).collect {|param| param}
	     style_replace(self.style + self.find_page_layout(controller, action).get_styles, @style_params)
	  end

	  def resolve_layout_params(controller, action)
	     if @layout_params.nil?
	        @layout_params = {}
	        self.params.where(:param_class=>:local).each do |param|
	           @layout_params[param.name] = param.value
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
          self.table_name= "page_layouts"

	  has_many        :params, :class_name=>"Roxiware::Param::Param", :as=>:param_object, :autosave=>true, :dependent=>:destroy
          has_many        :layout_sections, :autosave=>true, :dependent=>:destroy
          belongs_to      :layout

	  attr_accessible :render_layout    # location of the rendering file for the layout
          attr_accessible :controller       # controller determining when to render this layout
          attr_accessible :action           # action determining when to render this layout
          attr_accessible :style            # per_page style for this layout
	  attr_accessible :layout_id


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
	       xml_page_layout.style {|s| s.cdata!(self.style)}
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
	  
	  def get_styles
	     @style_cache ||= style_replace(self.style + self.layout_sections.collect{|section| section.get_styles}.join(" "), self.params.where(:param_class=>:style))
	     @style_cache
	  end

	  def resolve_layout_params
	     if @layout_params.nil?
	        @layout_params = {}
	        self.params.where(:param_class=>:local).each do |param|
	           @layout_params[param.name] = param.value
	        end
             end
	     @layout_params
          end

	  def section(section_name)
	     if @sections.blank?
	        @sections = {}
	        layout_sections.each do |layout_section|
		   @sections[layout_section.name] = layout_section
		end
             end
	     @sections[section_name]
	  end

      end

      # LayoutSection
      # Represents an ordered set of widgets, applied to a 
      # layout section such as the 'left_bar'

      class LayoutSection < ActiveRecord::Base
          include Roxiware::BaseModel
          self.table_name= "layout_sections"

	  has_many        :widget_instances, :autosave=>true, :dependent=>:destroy
	  belongs_to      :page_layout
	  attr_accessible :name               # name of the layout section ('left_bar', etc)
	  attr_accessible :style              # style content, containing style applied when the widget is to be rendered
	  attr_accessible :page_layout_id     # page layout

	  def import(layout_section_node)
	     self.name = layout_section_node["name"]
	     self.style = layout_section_node.find_first("style").content
	     widget_instance_nodes = layout_section_node.find("widget_instances/instance")
	     widget_instance_nodes.each do |widget_instance_node|
                widget_instance = self.widget_instances.build
		widget_instance.import(widget_instance_node)
	     end
	     params = layout_section_node.find("params/param")
	     params.each do |param|
               param = self.params.build
               param.import(param)
	     end
	  end

          def export(xml_layout_sections)
	     xml_layout_sections.section(:name=>self.name) do |xml_layout_section|
	       xml_layout_section.style {|s| s.cdata!(self.style)}
	       xml_layout_section.widget_instances do |xml_widget_instances|
	          self.widget_instances.each do |widget_instance|
		     widget_instance.export(xml_widget_instances)
		  end
	       end
	     end
          end

	  def get_styles
	     return self.style + self.widget_instances.collect{|instance| instance.get_styles}.join(" ")
	  end
      end

      # Widget
      # Contains references to basic 'controller' code, style for the widget.  
      class Widget < ActiveRecord::Base
          include Roxiware::BaseModel
          self.table_name= "widgets"
	  has_many        :params, :class_name=>"Roxiware::Param::Param", :as=>:param_object, :autosave=>true, :dependent=>:destroy

	  attr_accessible :name              # display name of the widget
	  attr_accessible :version           # version of the widget
	  attr_accessible :description       # text description of the widget
	  attr_accessible :preload           # code run to generate active locals, and determine whether to show the widget
	  attr_accessible :render_view       # code to render the view
	  attr_accessible :guid              # unique identifier for this widget
	  attr_accessible :style             # style for the widget

          def import(widget_node)
	     self.version = widget_node["version"]
	     self.guid = widget_node["guid"]
	     self.name = widget_node.find_first("name").content
	     self.description = widget_node.find_first("description").content    
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
	        xml_widget.description self.description
	        xml_widget.preload {|s| s.cdata!(self.preload)}
	        xml_widget.render_view {|s| s.cdata!(self.render_view)}
	        xml_widget.style {|s| s.cdata!(self.style)}
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
          self.table_name= "widget_instances"

	  has_many   :params, :class_name=>"Roxiware::Param::Param", :as=>:param_object, :autosave=>true, :dependent=>:destroy
	  belongs_to :layout_section

	  attr_accessible :layout_section_id  # the layout this widget instancebelongs to
	  attr_accessible :section_order      # the order in which this widget should be rendered
	  attr_accessible :widget_guid        # the widget this instance references

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
	  
	  def get_styles
	     return style_replace(self.widget.style, self.params.where(:param_class=>:style))
	  end

	  def get_params
	     if @params.nil?
	        @params = {}
	        params.where(:param_class=>:local).each do |param|
                   @params[param.name.to_sym] = param.value
                end
             end
	     @params
          end
      end
   end
end
