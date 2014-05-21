require 'xml'
module Roxiware
    module Layouts
        class WidgetController < ApplicationController
            before_filter :_load_role, :unless=>[]
            skip_after_filter :store_location

            before_filter do
                layout_guid = params[:layout_id] || @current_template
                @layout = Roxiware::Layout::Layout.where(:guid=>params[:layout_id]).first
                raise ActiveRecord::RecordNotFound if @layout.nil?
                authorize! :read, @layout

                @page_layout = @layout.page_layout_by_url(@layout.id, params[:page_id])
                raise ActiveRecord::RecordNotFound if @page_layout.nil?
                authorize! :read, @page_layout

                @layout_section = @page_layout.section(params[:section_id])
                raise ActiveRecord::RecordNotFound if @layout_section.nil?
                authorize! :read, @layout_section
            end

            # list all layouts
            def index
                pages = Roxiware::Layout::WidgetInstance.all
                @pages = []
                pages.each do |page|
                    authorize! :read, page
                    @pages << {:controller=>page[:controller], :action=>page[:action], :name=>page[:name]}
                end
                respond_to do |format|
                    format.json {render :json =>@pages}
                end
            end

            def edit
                @widget_instance = Roxiware::Layout::WidgetInstance.where(:id=>params[:id]).first
                raise ActiveRecord::RecordNotFound if @widget_instance.nil?
                authorize! :read, @widget_instance
                locals = {}
                locals[:widget_instance]=@widget_instance
                widget_instance_id = @widget_instance.get_param("widget_instance_id").to_s
                widget_instance_id = "widget-#{@widget_instance.id}" if widget_instance_id.blank?
                locals[:widget_instance_id] = widget_instance_id
                locals[:layout_section]=@layout_section
                locals[:page_layout]=@page_layout
                locals[:layout]=@current_layout
                respond_to do |format|
                    if @widget_instance.widget.editform.present?
                        format.html { render :inline => @widget_instance.widget.editform, :locals=>locals }
                    else
                        format.html { render :partial => "roxiware/settings/edit_widget_instance_form", :locals=>locals }
                    end
                end
            end


            def move
                success = true
                @widget_instance = @layout_section.widget_instance_by_id(params[:id])
                raise ActiveRecord::RecordNotFound if @widget_instance.nil?
                authorize! :move, @widget_instance
                moved_instances = {}
                target_section = @page_layout.section(params[:target_section])
                raise ActiveRecord::RecordNotFound if target_section.nil?

                target_order = params[:target_order].to_i
                raise ActiveRecord::RecordNotFound if target_order.nil?

                ActiveRecord::Base.transaction do
                    begin
                        if(target_section == @layout_section)
                            if (@widget_instance.section_order < target_order)
                                target_order = target_order - 1
                            end
                        end
                        @layout_section.widget_instance_delete(@widget_instance)
                        target_section.widget_instance_insert(target_order, @widget_instance)
                    rescue Exception => e
                        puts e.message
                        puts e.backtrace.join("\n")
                        @widget_instance.errors.add(:base, e.message)
                        success = false
                        raise ActiveRecord::Rollback
                    end
                end
                if success
                    @page_layout.refresh_styles
                    @layout_section.refresh
                    target_section.refresh
                end

                respond_to do |format|
                    if success
                        @layout.clear_instance_globals(@widget_instance.id)
                        @layout_section.refresh
                        @page_layout.refresh_styles
                        format.json { render :json => moved_instances }
                    else
                        format.json { render :json=>report_error(@widget_instance)}
                    end
                end
            end

            def create
                authorize! :create, Roxiware::Layout::WidgetInstance

                target_order = params[:section_order].to_i
                if target_order < 0
                    target_order = 1
                    target_order += @layout_section.get_widget_instances.last.section_order if @layout_section.get_widget_instances.last
                end

                @layout_section.widget_instances.where("section_order >= #{target_order}").each do |instance|
                    Roxiware::Layout::WidgetInstance.increment_counter(:section_order, instance.id)
                end
                @widget_instance = @layout_section.widget_instances.create({:widget_guid=>params[:widget_guid], :section_order=>target_order}, :as=>@role)
                @widget_instance.widget = Roxiware::Layout::Widget.where(:guid=>params[:widget_guid]).first
                @widget_instance.save!
                @layout_section.save!
                @layout_section.refresh
                @page_layout.refresh_styles
                respond_to do |format|
                    format.html { redirect_to "/", :notice => 'Widget was successfully added.' }
                    format.json { render :json => @widget_instance.ajax_attrs(@role) }
                end
            end

            def update
                @widget_instance = @layout_section.widget_instance_by_id(params[:id].to_i)
                raise ActiveRecord::RecordNotFound if @widget_instance.nil?
                authorize! :update, @widget_instance
                success = true
                ActiveRecord::Base.transaction do
                    begin
                        if params[:params].present?
                            params[:params].each do |name, value|
                                # as no description guid and class are included, set_param
                                # will require an existing param with the given name is
                                # present.
                                @widget_instance.set_param(name, value)
                            end
                        end
                        if params[:format] == "xml"
                            # request is xml, so import it.
                            parser = XML::Parser.io(request.body)
                            if parser.blank?
                                raise ActiveRecord::Rollback
                            end
                            doc = parser.parse
                            param_nodes = doc.find("/widget_params/param")
                            param_nodes.each do |param_node|
                                param = Roxiware::Param::Param.new
                                param.import(param_node, false)
                                puts "SETTING #{param.name} to #{param.inspect}"
                                @widget_instance.set_param(param.name, param)
                            end
                        end
                        @widget_instance.assign_attributes(params, :as=>@role)
                        @widget_instance.save!
                    rescue Exception => e
                        @widget_instance.errors.add(:base, e.message)
                        puts e.message
                        puts e.backtrace.join("\n")
                        success = false
                    end
                end
                respond_to do |format|
                    if success
                        @layout.clear_instance_globals(@widget_instance.id)
                        refresh_layout
                        format.xml  { render :xml => {:success=>true} }
                        format.html { redirect_to return_to_location("/"), :notice => 'widget settings were successfully updated.' }
                        format.json { render :json => @widget_instance.ajax_attrs(@role) }
                    else
                        format.html { redirect_to return_to_location("/"), :alert => 'Failure updating widget settings.' }
                        format.xml  { head :fail }
                        format.json { render :json=>report_error(@widget_instance)}
                    end
                end
            end

            def destroy
                @widget_instance = Roxiware::Layout::WidgetInstance.where(:id=>params[:id]).first
                raise ActiveRecord::RecordNotFound if @widget_instance.nil?
                authorize! :destroy, @widget_instance
                moved_instances = {}
                order = @widget_instance.section_order
                respond_to do |format|
                    if @widget_instance.destroy
                        section_order=0
                        @layout_section.widget_instances.order(:section_order).each do |instance|
                            instance.section_order = section_order
                            instance.save!
                            moved_instances[instance.id] = {:section=>@layout_section, :position=>section_order}
                            section_order += 1
                        end
                        refresh_layout
                        format.html { redirect_to return_to_location("/"), :notice => 'Widget was successfully deleted.' }
                        format.json { render :json => moved_instances }
                    else
                        format.html { redirect_to return_to_location("/"), :alert => 'Failure updating widget settings.' }
                        format.json { render :json=>report_error(@widget_instance)}
                    end
                end
            end

            private
            def _load_role
                @role = "guest"
                @role = current_user.role unless current_user.nil?
                @person_id = (current_user && current_user.person)?current_user.person.id : -1
            end
        end
    end
end

