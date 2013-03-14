require 'xml'
module Roxiware
  module Layouts
    class WidgetController < ApplicationController
       before_filter :_load_role, :unless=>[]
       skip_after_filter :store_location
       
       before_filter do
           if(@current_layout.guid == params[:layout_id])
	      @layout = @current_layout
	   else
	      @layout = Roxiware::Layout::Layout.where(:guid=>params[:layout_id]).first
           end
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
	   widget_instance_id = "widget-#{@widget_instance.id}" if @widget_instance_id.blank?
	   locals[:widget_instance_id] = widget_instance_id
	   locals[:layout_section]=@layout_section 
	   locals[:page_layout]=@page_layout
	   locals[:layout]=@current_layout 
	   puts locals.inspect
           respond_to do |format|
	     if @widget_instance.widget.editform.present?
               format.html { render :inline => @widget_instance.widget.editform, :locals=>locals }
	     else
               format.html { render :partial => "roxiware/settings/edit_widget_instance_form", :locals=>locals }
	     end
	   end
       end

       def move
           @widget_instance = @layout_section.get_widget_instances.where(:id=>params[:id]).first
	   raise ActiveRecord::RecordNotFound if @widget_instance.nil?
	   authorize! :move, @widget_instance

	   moved_instances = {}
	   target_section = @page_layout.section(params[:target_section])
	   target_order = params[:target_order].to_i

	   source_section_ids = []
	   dest_section_ids = []
	   @layout_section.get_widget_instances.each do |instance|
	      source_section_ids << instance.id if(instance != @widget_instance)
              if (instance.section_order > @widget_instance.section_order)
	        moved_instances[instance.id] = {:section=>@layout_section.name, :position=>instance.section_order, :increment=>false}
              end
	   end
	   
	   if(target_order > 0)
              target_section.get_widget_instances.each do |instance|
	        dest_section_ids << instance.id if(instance != @widget_instance)
                if instance.section_order >= target_order
		  if moved_instances[instance.id].blank?
	             moved_instances[instance.id] = {:section=>target_section.name, :position=>instance.section_order, :increment=>true}
		  else
		     moved_instances.delete(instance.id)
		  end
                end
	      end
	   end

	   moved_instances.each do |instance_id, target|
	      if target[:increment]
	         Roxiware::Layout::WidgetInstance.increment_counter(:section_order, instance_id)
		 target[:position] += 1
	      else
	         Roxiware::Layout::WidgetInstance.decrement_counter(:section_order, instance_id)
		 target[:position] -= 1
	      end
	      target.delete(:increment)
	   end

	   dest_section_ids << @widget_instance.id
	   if target_order > 0
             @widget_instance.section_order = target_order
	   else
	      if target_section.get_widget_instances.last.blank?
	         last_order = 1
	      else
	         last_order = target_section.get_widget_instances.last.section_order + 1
	      end
	      @widget_instance.section_order = last_order
	   end
	   @widget_instance.layout_section_id = target_section.id
	   @widget_instance.save!
	   

	   @layout_section.save!
	   target_section.save!
	   @page_layout.refresh_styles
	   @layout_section.refresh
	   target_section.refresh

           moved_instances[@widget_instance.id] = {:section=>@widget_instance.layout_section.name, :position=>@widget_instance.section_order}
	   respond_to do |format|
	       format.json { render :json=>moved_instances}
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
           @widget_instance = Roxiware::Layout::WidgetInstance.where(:id=>params[:id]).first
	   raise ActiveRecord::RecordNotFound if @widget_instance.nil?
	   authorize! :update, @widget_instance
	   success = true
           ActiveRecord::Base.transaction do
	      begin
	         if params[:params].present?
		   @widget_instance.get_param_objs.values.each do |instance_param|
		      if params[:params][instance_param.name.to_sym].present?
			 # if it's a widget param, we won't have an instance param for it
			 # so create a new param object and add it
			 if (instance_param.param_object_type == "Roxiware::Layout::Widget") && 
			    (instance_param.value != params[:params][instance_param.name.to_sym])
			     instance_param = @widget_instance.params.build(
				  {:param_class=>instance_param.param_class, 
				      :name=>instance_param.name, 
				      :description_guid=>instance_param.description_guid}, :as=>"")
			  if instance_param.blank?
			     raise ActiveRecord::Rollback
			  end
			end
			if instance_param.present?
			     instance_param.value = params[:params][instance_param.name.to_sym]
			     instance_param.save!
			 end
		      end
                   end
		 end
		 if params[:format] == "xml"
		     # request is xml, so import it.
		     print "IMPORTING XML\n"
		     parser = XML::Parser.io(request.body)
		     if parser.blank?
			raise ActiveRecord::Rollback
		     end
		     doc = parser.parse
		     param_nodes = doc.find("/widget_params/param")
		     param_nodes.each do |param_node|
		         print "importing #{param_node['name']}\n"
			 param = @widget_instance.get_param(param_node["name"])
                         param.destroy if param.present? && (param.param_object_type == "Roxiware::Layout::WidgetInstance")
			 param = @widget_instance.params.build
			 if param.blank?
			    raise ActiveRecord::Rollback
			 end
			 print "doing import\n"
			 param.import(param_node, false)
		     end
		 end
		 if !@widget_instance.update_attributes(params, :as=>@role)
		    raise ActiveRecord::Rollback
		 end 
	      rescue Exception => e
	         print e.message
	         success = false
	      end
           end
	   respond_to do |format|
	       if success
		  @widget_instance.clear_globals
                  @layout_section.refresh
	          @page_layout.refresh_styles
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
	         @page_layout.refresh_styles
                 @layout_section.widget_instances.where("section_order > #{order}").each do |instance|
                     Roxiware::Layout::WidgetInstance.increment_counter(:section_order, instance.id)
		     moved_instances[instance.id] = {:section=>@layout_section, :position=>instance.section_order}
	         end
	         @layout_section.refresh
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

