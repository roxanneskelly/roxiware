require 'uri'
require 'sass'
require 'securerandom'

def child_cdata_content(element)
    if element.present? && element.children.present?
        (element.children.select{|child| child.cdata?} || []).collect{|child| child.content}.join("")
    else
        ""
    end
end

module Roxiware
    module Layout
        module LayoutBase
            def self.included(base)
            end

            class StyleRenderClass
                include Roxiware::Helpers
                def initialize(params_in)
                    params_in.each do |key, value|
                        singleton_class.send(:define_method, key) { value }
                    end
                end
                def get_binding
                    binding
                end
            end

            def style_params
                get_params(:style)
            end

            def eval_style(params_in)
                puts "STYLE PARAMS IN #{params_in.inspect}"
                style_class = StyleRenderClass.new(params_in)
                ERB.new(self.style).result(style_class.get_binding)
            end

            # validate_style
            def validate_style(syntax_check_params)
                validate_errors = []
                begin
                    style_params = {}
                    Sass::Engine.new(eval_style(syntax_check_params).strip, {
                                         :style=>:expanded,
                                         :syntax=>:scss,
                                         :cache=>false
                                     }).render()
                rescue Sass::SyntaxError => e
                    puts "#{e.message}  on line #{e.sass_line}"
                    puts e.inspect
                    puts e.sass_backtrace.inspect
                    validate_errors << [e.sass_line, e.message]
                end
                validate_errors
            end
        end


        # Layout
        # overall layout
        class Layout < ActiveRecord::Base
            include Roxiware::BaseModel
            include Roxiware::Layout::LayoutBase
            include Roxiware::Param::ParamClientBase

            self.table_name= "layouts"
            PUBLIC_PACKAGES = %w(basic-blog premium-blog basic-author premium-author basic-form premium-forum)
            ADMIN_PACKAGES = %w(custom basic-blog premium-blog basic-author premium-author basic-form premium-forum)

            after_initialize :init_layout
            after_find :init_layout

            has_many :term_relationships, :as=>:term_object, :class_name=>"Roxiware::Terms::TermRelationship", :dependent=>:destroy, :autosave=>true
            has_many :terms, :through=>:term_relationships, :class_name=>"Roxiware::Terms::Term", :autosave=>true

            has_many :params, :class_name=>"Roxiware::Param::Param", :as=>:param_object, :autosave=>true, :dependent=>:destroy
            has_many :page_layouts, :autosave=>true, :dependent=>:destroy

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

            edit_attr_accessible :description, :thumbnail_url, :preview_url, :style, :setup, :name, :category_csv, :settings_form, :as=>[:super, nil]
            ajax_attr_accessible :guid, :name, :description, :category_csv, :thumbnail_url, :preview_url, :as=>[:super, :admin, :guest, nil]

            def get_by_path(path)
                path_components = path.split("/", 2)
                return self if(path_components.blank?)

                page_components = path_components.shift.split("_",2)
                page_params = {}
                page_params[:application] = (page_components[0] || "")
                page_params[:application_path] = page_components[1] || ""
                page_layout = find_page_layout(page_params)
                if (page_layout.action != page_params[:application_path]) || (page_layout.application != page_params[:application])
                    raise Exception.new("param_by_path: Page not found #{path}")
                end
                page_layout.get_by_path(path_components.shift)
            end

            def deep_dup
                new_layout = dup
                # update to SecureRandom.uuid when we switch to ruby 1.9
                new_layout.guid = SecureRandom.hex.sub(/(.{8})(.{4})(.{4})(.{4})(.*)/, '\1-\2-\3-\4-\5')
                index = 1
                while Roxiware::Layout::Layout.where(:name=>"#{new_layout.name}(#{index})").first.present?
                    index = index + 1
                end
                new_layout.name = "#{new_layout.name}(#{index})"

                new_layout.page_layouts = page_layouts.collect{|p| p.deep_dup}
                new_layout.params = params.collect{|p| p.deep_dup}
                new_layout.term_relationships = term_relationships.collect{|r| r.dup}

                # fixup scheme UUIDs
                schemes = {}
                get_param("schemes").h.each do |scheme_id, scheme|
                    new_scheme = scheme.deep_dup
                    # update to SecureRandom.uuid when we switch to ruby 1.9
                    new_scheme.name = SecureRandom.hex.sub(/(.{8})(.{4})(.{4})(.{4})(.*)/, '\1-\2-\3-\4-\5')
                    schemes[new_scheme.name] = new_scheme
                end
                new_layout.set_param("schemes", schemes)
                new_layout
            end

            def instance_globals(instance_id)
                @@globals ||= {}
                @@globals[instance_id] ||= {}
                @@globals[instance_id]
            end

            def clear_instance_globals(instance_id)
                @@globals ||= {}
                @@globals[instance_id] = {}
            end

            def clear_globals
                @@globals = {}
            end


            def category_ids
                self.categories.collect{|term| term.id}
            end

            def category_ids=(category_ids)
                self.term_ids = (self.package_ids.to_set + category_ids.to_set).to_a
            end

            def category_csv
                self.categories.collect{|term| term.name}.join(", ")
            end

            def category_csv=(csv)
                category_strings = csv.split(",").collect {|x| x.gsub(/[^a-z0-9]+/i,' ').gsub(/\s+/,' ').strip.titleize}.select{|y| !y.empty?}
                self.category_ids = Roxiware::Terms::Term.get_or_create(category_strings, Roxiware::Terms::TermTaxonomy::LAYOUT_CATEGORY_NAME).map{|term| term.id}
            end

            def categories
                self.terms.where(:term_taxonomy_id=>Roxiware::Terms::TermTaxonomy.taxonomy_id(Roxiware::Terms::TermTaxonomy::LAYOUT_CATEGORY_NAME))
            end

            def package_ids
                self.packages.collect{|term| term.id}
            end

            def package_ids=(package_ids)
                self.term_ids = (self.category_ids.to_set + package_ids.to_set).to_a
            end

            def package_csv
                self.packages.collect{|term| term.name}.join(", ")
            end

            def package_csv=(csv)
                package_strings = csv.split(",")
                self.package_ids = Roxiware::Terms::Term.get_or_create(package_strings, Roxiware::Terms::TermTaxonomy::LAYOUT_PACKAGE_NAME).map{|term| term.id}
            end

            def packages
                self.terms.where(:term_taxonomy_id=>Roxiware::Terms::TermTaxonomy.taxonomy_id(Roxiware::Terms::TermTaxonomy::LAYOUT_PACKAGE_NAME))
            end

            def import(layout_node)
                self.guid = layout_node["guid"]
                # import layout chooser information
                self.name = layout_node.find_first("name").content
                self.thumbnail_url = layout_node.find_first("thumbnail_url").content
                self.preview_url = layout_node.find_first("preview_url").content
                self.description = child_cdata_content(layout_node.find_first("description"))
                self.settings_form = child_cdata_content(layout_node.find_first("settings_form"))
                layout_category_nodes = layout_node.find("categories/category")

                # generate a list of categories, cleaning them up and splitting them into sub categories
                # Sub categories are split by '/' as in 'Sci-Fi/Military' and will be split into 'Sci-Fi' and 'Sci-Fi/Military'
                categories = Set.new([])
                layout_category_nodes.collect{|layout_category_node| layout_category_node.content}.each do |category|
                    category_elems = category.split("/")
                    while category_elems.present?
                        categories.add(category_elems.join("/"))
                        category_elems = category_elems.take(category_elems.length-1)
                    end
                end

                layout_package_nodes = layout_node.find("packages/package")
                packages = layout_package_nodes.collect{|layout_package_node| layout_package_node.content}
                self.term_ids = (Roxiware::Terms::Term.get_or_create(packages, Roxiware::Terms::TermTaxonomy::LAYOUT_PACKAGE_NAME).map{|term| term.id} + Roxiware::Terms::Term.get_or_create(categories, Roxiware::Terms::TermTaxonomy::LAYOUT_CATEGORY_NAME).map{|term| term.id})

                self.style = child_cdata_content(layout_node.find_first("style"))
                self.setup = child_cdata_content(layout_node.find_first("setup"))
                page_layout_nodes = layout_node.find("pages/page")
                page_layout_nodes.each do |page_layout_node|
                    page_layout = self.page_layouts.build
                    page_layout.import(page_layout_node)
                end
                params = layout_node.find("params/param")
                params.each do |param|
                    layout_param = self.params.build
                    layout_param.import(param, true)
                end
                page_layout_nodes = nil
            end

            def export(xml_layouts)
                xml_layouts.layout(:version=>"1.0", :guid=>self.guid) do |xml_layout|
                    xml_layout.comment!("Roxiware Web Engine Template: #{self.name}")
                    xml_layout.name self.name
                    xml_layout.thumbnail_url self.thumbnail_url
                    xml_layout.preview_url self.preview_url
                    xml_layout.description {xml_layout.cdata!(self.description)}
                    xml_layout.setup {xml_layout.cdata!(self.setup || "")}
                    xml_layout.settings_form {xml_layout.cdata!(self.settings_form || "")}
                    xml_layout.categories do |xml_categories|
                        self.categories.sort{|x, y| x.name <=> y.name}.each do |term|
                            xml_categories.category term.name
                        end
                    end
                    xml_layout.packages do |xml_packages|
                        self.packages.sort{|x,y| x.name <=> y.name}.each do |term|
                            xml_packages.package term.name
                        end
                    end
                    xml_layout.style {xml_layout.cdata!(self.style) }
                    xml_layout.params do |xml_params|
                        self.get_param_obj_list.each do |param|
                            param.export(xml_params, true)
                        end
                    end
                    xml_layout.pages do |xml_page_layouts|
                        self.page_layouts.sort{|x, y| x.get_url_identifier <=> y.get_url_identifier}.each do |page_layout|
                            page_layout.export(xml_page_layouts)
                        end
                    end
                end
            end

            def find_page_layout(params)
                stack = page_layout_stack(params)
                stack[-1] if stack.present?
            end

            def page_layout_by_url(layout_id, url_identifier)
                page_id = URI.decode(url_identifier).split("_",2)
                find_page_layout({:application=>(page_id[0] || ""), :application_path=>(page_id[1] || "")})
            end

            def init_layout
                page_layout_list = self.page_layouts.collect {|page_layout| page_layout}
                page_layout_list.each{|page_layout| page_layout.layout = self}
                @page_layout_cache=[]
                @page_layout_cache.concat(self.page_layouts.reject {|page_layout| page_layout.application.present?})
                @page_layout_cache.concat(self.page_layouts.reject {|page_layout| page_layout.application.blank? || page_layout.action.present?})
                @page_layout_cache.concat(self.page_layouts.reject {|page_layout| page_layout.application.blank? || page_layout.action.blank?})
            end

            def page_layout_stack(params)
                if @page_layout_cache.blank?
                    # init_layout
                end

                result = []
                @page_layout_cache.each do |page_layout|
                    if(page_layout.is_root? || (page_layout.application == params[:application]) && (page_layout.action.blank? || (page_layout.action == params[:application_path])))
                        page_layout.refresh_sections_if_needed(result[-1])
                        result <<  page_layout
                    end
                end
                result
            end

            def get_styles(scheme, params_in)
                page_layout = find_page_layout(params_in)

                if(scheme != @current_scheme)
                    @current_scheme = scheme
                    @layout_params_cache = nil
                    @compiled_style_cache = nil
                end

                if(@layout_params_cache.blank?)
                    @layout_params_cache = get_scheme_param_values(scheme).merge(style_params)
                    @compiled_style_cache = nil
                    page_layout.refresh_styles
                end

                if(@compiled_style_cache.nil?)
                    @compiled_style_cache = Sass::Engine.new(eval_style(@layout_params_cache).strip, {
                                                                 :style=>:expanded,
                                                                 :syntax=>:scss,
                                                                 :cache=>false
                                                             }).render()
                end
                @compiled_style_cache + page_layout.get_styles(@layout_params_cache)
            end

            def get_scheme_params(scheme)
                scheme = get_param("schemes").h[scheme] if get_param("schemes").present?
                if(scheme.present? && scheme.h["params"].present?)
                    result = Hash[scheme.h["params"].h.collect{|name, param| [name, param]}]
                else
                    {}
                end
            end

            def get_scheme_param_values(scheme_name)
                result = {}
                puts "SCHEME PARAMS for scheme #{scheme_name}"
                schemes =get_param("schemes")
                puts "SCHEME list  " + schemes.h.collect{ |name, value| "#{name} :  #{value.inspect}" }.join("\n")
                puts "SCHEME PARAMS in scheme #{schemes.h[scheme_name].inspect}"
                scheme = get_param("schemes").h[scheme_name] if get_param("schemes").present?
                puts scheme.inspect
                if(scheme.present? && scheme.h["params"].present?)
                    result = Hash[scheme.h["params"].h.collect{|name, param| [name, param.conv_value]}]
                end
                result.merge!(Hash[self.custom_settings.h.values.collect{|param| [param.name, param.conv_value]}])
                result
            end

            def custom_settings
                if @custom_settings.nil?
                    @custom_settings  = Roxiware::Param::Param.application_param_hash("custom_settings")[self.guid] || Roxiware::Param::Param.set_application_param("custom_settings", self.guid, "371BA63A-EEDB-440D-B641-40A6B813D280", {})
                    puts "CUSTOM SETTINGS for #{ self.guid } #{@custom_settings.h.inspect}"
                    # filter the custom settings by the scheme params
                    puts "SCHEMES #{get_param('schemes').h.inspect}"
                    scheme = get_param("schemes").h.first
                    scheme_params = scheme.last.h["params"].h.keys
                    @custom_settings.h.each do |key, value|
                        if !scheme_params.include?(key)
                            value.destroy
                        end
                    end
                end
                @custom_settings
            end

            def set_custom_setting(name, value)
                scheme = get_param("schemes").h.first
                scheme_param =scheme.last.h["params"].h[name]
                if(scheme_param.nil?)
                    puts "COULDN'T FIND SCHEME PARAM #{name}"
                end
                custom_settings.h[name] = custom_settings.set_param(name, value, scheme_param.description_guid, "custom_setting")
                custom_settings.h[name].save!
                custom_settings.h[name]
            end

            def reset_custom_settings
                @custom_settings  = Roxiware::Param::Param.application_param_hash("custom_settings")[self.guid]
                @custom_settings.destroy! if @custom_settings.present?
                @custom_settings = nil
            end

            def resolve_layout_params(scheme, params_in)
                page_layout = self.find_page_layout(params_in)
                puts "LAYOUT_PARAMS #{get_params(:local).inspect}"
                get_params(:local).merge(page_layout.resolve_layout_params).merge(get_scheme_param_values(scheme))
            end

            before_validation do
                self.description = Sanitize.clean(self.description, Roxiware::Sanitizer::BASIC_SANITIZER)
                self.style = self.style.gsub(/\r\n?/, "\n") if self.style.present?
                self.setup = self.setup.gsub(/\r\n?/, "\n") if self.setup.present?
                self.settings_form = self.settings_form.gsub(/\r\n?/, "\n") if self.settings_form.present?
            end
        end


        # Page Layout
        # Layout of columns, etc. per page
        class PageLayout < ActiveRecord::Base
            include Roxiware::BaseModel
            include Roxiware::Layout::LayoutBase
            include Roxiware::Param::ParamClientBase

            self.table_name= "page_layouts"

            has_many :params, :class_name=>"Roxiware::Param::Param", :as=>:param_object, :autosave=>true, :dependent=>:destroy
            has_many :layout_sections, :autosave=>true, :dependent=>:destroy

            edit_attr_accessible :render_layout, :style, :as=>[:super, nil]
            edit_attr_accessible :application, :action, :layout_id, :as=>[nil]
            ajax_attr_accessible :render_layout, :style, :application, :action, :layout_id, :as=>[:super, nil]

            attr_accessor :layout

            def get_by_path(path)
                path_components = path.split("/", 2)
                return self if(path_components.blank?)
                section = self.section(path_components.shift)
                if(section.blank?)
                    raise Exception.new("param_by_path: Section not found #{path}")
                end
                section.get_by_path(path_components.shift)
            end

            def deep_dup
                new_page_layout = dup
                new_page_layout.layout_sections = layout_sections.collect{|s| s.deep_dup}
                new_page_layout.params = params.collect{|p| p.deep_dup}
                new_page_layout
            end

            def get_url_identifier
                URI.encode("#{application}_#{action}", "/")
            end

            def set_url_identifier(url_identifier)
                page_id = URI.decode(url_identifier).split("_",2)
                self.application = page_id[0] || ""
                self.action = page_id[1] || ""
            end

            def is_root?
                application.blank? && action.blank?
            end

            def get_text_name
                result = ""
                result = self.application
                result = "base" if result.blank?
                result = result
                result += " "+self.action if self.action.present?
                result += " page"
                result.titleize
            end

            def import(page_layout_node)
                self.application    = page_layout_node["application"] || page_layout_node["controller"]
                self.action        = page_layout_node["action"]
                self.render_layout = page_layout_node.find_first("render_layout").content
                self.style = child_cdata_content(page_layout_node.find_first("style"))
                layout_section_nodes = page_layout_node.find("sections/section")
                layout_section_nodes.each do |layout_section_node|
                    layout_section = self.layout_sections.build
                    layout_section.import(layout_section_node)
                end
                params = page_layout_node.find("params/param")
                params.each do |param|
                    page_param = self.params.build
                    page_param.import(param, true)
                end
                layout_section_nodes = nil
            end

            def export(xml_page_layouts)
                xml_page_layouts.page(:application=>self.application, :action=>self.action) do |xml_page_layout|
                    xml_page_layout.render_layout self.render_layout
                    xml_page_layout.style {xml_page_layout.cdata!(self.style)}
                    xml_page_layout.params do |xml_params|
                        self.get_param_obj_list.each do |param|
                            param.export(xml_params, true)
                        end
                    end
                    xml_page_layout.sections do |xml_layout_sections|
                        self.layout_sections.sort{|x,y| x.name <=> y.name}.each do |layout_section|
                            layout_section.export(xml_layout_sections)
                        end
                    end
                end
            end

            def refresh_styles
                @compiled_style_cache = nil
            end

            def get_styles(params_in)
                if(@compiled_style_cache.blank?)
                    new_params = params_in.merge(style_params)
                    evaled_layout_style = eval_style(new_params) + self.sections.values.collect{|section| section.get_styles(new_params)}.join(" ")
                    begin
                        @compiled_style_cache = Sass::Engine.new(evaled_layout_style, {
                                                                     :style=>:expanded,
                                                                     :syntax=>:scss,
                                                                     :cache=>false
                                                                 }).render()
                    rescue Sass::SyntaxError=>e
                        puts e.message
                        puts self.inspect
                        sass_style = evaled_layout_style.split("\n")
                        sass_style[e.sass_line] = "--> " + sass_style[e.sass_line].to_s
                        puts sass_style.join("\n")
                        @compiled_style_cache = ""
                    end
                end
                @compiled_style_cache
            end

            def resolve_layout_params
                get_params(:local)
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
                    layout_section.page_layout = self
                    @sections[layout_section.name] = layout_section
                end
            end

            def sections
                @sections
            end

            def section(section_name)
                if @sections[section_name].blank?
                    @sections[section_name] = self.layout_sections.create({:name=>section_name, :style=>""}, :as=>"")
                    @sections[section_name].page_layout = self
                end
                @sections[section_name]
            end
            before_validation do
                self.style = self.style.gsub(/\r\n?/, "\n");
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

            has_many :params, :class_name=>"Roxiware::Param::Param", :as=>:param_object, :autosave=>true, :dependent=>:destroy
            has_many :widget_instances, :autosave=>true

            attr_accessor :page_layout

            edit_attr_accessible :style, :as=>[:super, nil]
            edit_attr_accessible :name, :as=>[nil]
            ajax_attr_accessible :name, :style, :page_layout_id, :as=>[:super, nil]

            def get_by_path(path)
                path_components = path.split("/", 2)
                return self if(path_components.blank?)
                widget_instance = self.get_widget_instance(path_components.shift)
                if(widget_instance.blank?)
                    raise Exception.new("param_by_path: Widget not found #{path}")
                end
                widget_instance.get_by_path(path_components.shift)
            end


            def deep_dup
                new_layout_section = dup
                new_layout_section.widget_instances = widget_instances.collect{|w| w.deep_dup}
                new_layout_section.params = params.collect{|p| p.deep_dup}
                new_layout_section
            end

            def get_text_name
                "#{name.split("_").join(" ")} section of #{self.page_layout.get_text_name}".titleize
            end

            def import(layout_section_node)
                self.name = layout_section_node["name"]
                self.style = child_cdata_content(layout_section_node.find_first("style"))
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
                    xml_layout_section.style {xml_layout_section.cdata!(self.style)}
                    xml_layout_section.params do |xml_params|
                        self.get_param_obj_list.each do |param|
                            param.export(xml_params, true)
                        end
                    end
                    xml_layout_section.widget_instances do |xml_widget_instances|
                        self.widget_instances.sort{|x,y| x.section_order <=> y.section_order}.each do |widget_instance|
                            widget_instance.export(xml_widget_instances)
                        end
                    end
                end
            end

            # Widget Instance Caching
            # Widget instance objects are cached on the layout_section to reduce
            # database lookouts of these very common objects.
            # they're maintained in an ordered list

            # clear out the ordered list.  It'll automatically be reloaded on next access
            def refresh
                @ordered_instances = nil
            end


            # retrieve the ordered list. Load it from the database if needed
            # Each instance also contains a cached refrerence to the layout_section,
            # so set that as well
            def get_widget_instances
                @ordered_instances ||= self.widget_instances
                @ordered_instances.each{|instance| instance.layout_section = self}
                @ordered_instances
            end

            # delete a widget instance from the layout section...both the cache and the actual
            # active record association
            # This will renumber the widget instances currently in the section
            # saving the new order
            def widget_instance_delete(instance_to_delete)
                widget_instances.delete(instance_to_delete)
                order = 0
                widget_instances.order(:section_order).each do |instance|
                    instance.section_order = order
                    instance.save!
                    order = order+1
                end
                save!
                @ordered_instances = nil
                instance_to_delete
            end

            # insert a widget into the layout section, both into the cache
            # and the active record association.  The widget instances will be renumbered
            def widget_instance_insert(index, insert_instance)
                instance_array = get_widget_instances.collect{|instance| instance}
                instance_array.insert(index, insert_instance)
                widget_instances << insert_instance
                @ordered_instances = nil
                order = 0
                instance_array.each do |instance|
                    instance.section_order = order
                    instance.save!
                    order = order+1
                end
                save!
                insert_instance
            end

            # get a widget instance from the instance cache by it's activerecord id
            #
            def widget_instance_by_id(instance_id)
                instances = get_widget_instances.collect{|instance|}
                get_widget_instances.select{|instance| instance.id = instance_id}.first
            end

            # get a widget instance by it's 'widget_instance_id' property.
            #
            def get_widget_instance(widget_id)
                get_widget_instances.select{|instance| widget_id == (instance.get_param("widget_instance_id").to_s)}.first
            end

            def get_styles(params)
                new_params = params.merge(style_params)
                eval_style(new_params) + self.widget_instances.collect{|instance| instance.get_styles(new_params)}.join(" ")
            end
            before_validation do
                self.style = self.style.gsub(/\r\n?/, "\n");
            end
        end

        # Widget
        # Contains references to basic 'controller' code, style for the widget.
        class Widget < ActiveRecord::Base
            include Roxiware::BaseModel
            include Roxiware::Layout::LayoutBase
            include Roxiware::Param::ParamClientBase
            self.table_name= "widgets"
            has_many :params, :class_name=>"Roxiware::Param::Param", :as=>:param_object, :autosave=>true, :dependent=>:destroy

            edit_attr_accessible :name, :version, :description, :preload, :render_view, :style, :editform, :as=>[:super, nil]
            ajax_attr_accessible :guid, :as=>[:super, nil]

            def self.get_widget(guid)
                @widgets ||= Hash[Roxiware::Layout::Widget.includes(:params).collect{|widget| [widget.guid, widget]}]
                @widgets[guid]
            end

            def import(widget_node)
                self.version = widget_node["version"]
                self.guid = widget_node["guid"]
                self.name = widget_node.find_first("name").content
                self.description = child_cdata_content(widget_node.find_first("description"))
                self.editform = child_cdata_content(widget_node.find_first("editform"))
                self.preload  = child_cdata_content(widget_node.find_first("preload"))
                self.render_view = child_cdata_content(widget_node.find_first("render_view"))
                self.style = child_cdata_content(widget_node.find_first("style"))
                params = widget_node.find("params/param")
                params.each do |param|
                    widget_param = self.params.build
                    widget_param.import(param, true)
                end
            end

            def export(xml_widgets)
                xml_widgets.widget(:version=>self.version, :guid=>self.guid) do |xml_widget|
                    xml_widget.name self.name
                    xml_widget.description {xml_widget.cdata!(self.description)}
                    xml_widget.editform {xml_widget.cdata!(self.editform)}
                    xml_widget.preload {xml_widget.cdata!(self.preload)}
                    xml_widget.render_view {xml_widget.cdata!(self.render_view)}
                    xml_widget.style {xml_widget.cdata!(self.style)}
                    xml_widget.params do |xml_params|
                        self.get_param_obj_list.each do |param|
                            param.export(xml_params, true)
                        end
                    end
                end
            end
            before_validation do
                self.style = self.style.gsub(/\r\n?/, "\n");
            end
        end

        # WidgetInstance
        # params, layout for the widget within the layout section
        class WidgetInstance < ActiveRecord::Base
            include Roxiware::BaseModel
            include Roxiware::Layout::LayoutBase
            include Roxiware::Param::ParamClientBase
            self.table_name= "widget_instances"

            has_many :params, :class_name=>"Roxiware::Param::Param", :as=>:param_object, :autosave=>true, :dependent=>:destroy

            edit_attr_accessible :layout_section_id, :section_order, :widget_guid, :as=>[:super, nil]
            ajax_attr_accessible :layout_section_id, :section_order, :widget_guid, :as=>[:super, nil]
            attr_accessor :layout_section
            default_scope ->{order(:section_order)}

            def deep_dup
                new_widget_instance = dup
                new_widget_instance.params = params.collect{|p| p.deep_dup}
                new_widget_instance
            end

            def globals
                layout_section.page_layout.layout.instance_globals(self.id)
            end

            def clear_globals
                layout_section.page_layout.layout.clear_instance_globals(self.id)
            end

            def widget
                Roxiware::Layout::Widget.get_widget(self.widget_guid)
            end

            def widget=(newwidget)
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

            def get_styles(base_params)
                self.widget.eval_style(base_params.merge(style_params))
            end

            def get_param_objs
                @param_objs ||= widget.get_param_objs.merge(Hash[self.params.collect{|param| [param.name.to_sym, param]}])
                @param_objs
            end

            def resolve_params
                Hash[get_param_objs.collect{|key, param| [key, param.conv_value]}]
            end
        end
    end
end
