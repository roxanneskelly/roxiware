module Roxiware
  module Layouts
    class SectionController < ApplicationController
       before_filter :_load_role, :unless=>[]
       skip_after_filter :store_location
       
       before_filter do
	   @layout = Roxiware::Layout::Layout.where(:guid=>params[:layout_id]).first
	   raise ActiveRecord::RecordNotFound if @layout.nil?
	   authorize! :read, @layout
           page_identifier = params[:page_id].split("#")
	   page_identifier << ""
           @page = @layout.find_page_layout(page_identifier[0], page_identifier[1])
	   raise ActiveRecord::RecordNotFound if @page.nil?
	   authorize! :read, @page
       end

       # list all sections
       def index
          section = Roxiware::Layout::LayoutSection.all
	  @sections = {}
	  sections.each do |section|
  	     authorize! :read, section
	     @sections[section.name] = section
	  end
          respond_to do |format|
	     format.json {render :json =>@sections}
	  end
       end
       
       def show
           @section = @page.section(params[:id])
	   raise ActiveRecord::RecordNotFound if @section.nil?
	   authorize! :read, @section
           respond_to do |format|
	     format.html { render :partial => "roxiware/shared/edit_section_layout_form" }
	   end
       end

       def update
           @section = @page.section(params[:id])
	   raise ActiveRecord::RecordNotFound if @section.nil?
	   authorize! :update, @section
	   success = true
           ActiveRecord::Base.transaction do
	      begin
	         if params[:params].present?
	            @section.params.each do |section_param|
		       if params[:params][section_param.name.to_sym].present?
		          section_param.value = params[:params][section_param.name.to_sym]
			  section_param.save!
		       end
		    end
		 end
		 if !@section.update_attributes(params, :as=>@role)
		    raise ActiveRecord::Rollback
		 end 
	      rescue Exception => e
	         print e.message
	         success = false
	      end
           end

	   respond_to do |format|
	       if success
		  refresh_layout
		  format.xml  { render :xml => {:success=>true} }
		  format.html { redirect_to return_to_location("/"), :notice => 'layout was successfully updated.' }
		  format.json { render :json => @section.ajax_attrs(@role) }
	       else
		  format.html { redirect_to return_to_location("/"), :alert => 'Failure updating layout.' }
		  format.xml  { head :fail }
		  format.json { render :json=>report_error(@section)}
	       end
	   end
       end

       def create
	   authorize! :create, Roxiware::Layout::LayoutSection
	   section_params = params[:params]
	   
           @section = @page.layout_sections.build
	   if(section_params[:clone].present?)
	      clone_section = Roxiware::Layout::LayoutSection.find(section_params[:clone])
	      raise ActiveRecord::RecordNotFound if clone_section.nil?
	      @section.update_attributes(clone_section.attributes, :as=>"")
	      clone_section.params.each do |section_param|
	          # NOTE, recursive params?
	          @section.params << section_param.dup
	      end
	   end
	   @section.name = section_params[:section]
	   success = true
           ActiveRecord::Base.transaction do
	      begin
	         if params[:params].present?
	            @section.params.each do |section_param|
		       if params[:params][section_param.name.to_sym].present?
		          section_param.value = params[:params][section_param.name.to_sym]
			  section_param.save!
		       end
		    end
		 end
		 if !@section.update_attributes(params, :as=>@role)
		    raise ActiveRecord::Rollback
		 end 
	      rescue Exception => e
	         print e.message
	         success = false
	      end
           end

	   respond_to do |format|
	       if success
		  refresh_layout
		  format.xml  { render :xml => {:success=>true} }
		  format.html { redirect_to return_to_location("/"), :notice => 'layout was successfully updated.' }
		  format.json { render :json => @section.ajax_attrs(@role) }
	       else
		  format.html { redirect_to return_to_location("/"), :alert => 'Failure updating layout.' }
		  format.xml  { head :fail }
		  format.json { render :json=>report_error(@section)}
	       end
	   end
       end


       def destroy
           @section = @page.section(params[:id])
	   raise ActiveRecord::RecordNotFound if @section.nil?
	   authorize! :destroy, @section
	   success = true

	   respond_to do |format|
	      if @section.destroy
	      	 refresh_layout
		 format.html {redirect_to return_to_location("/"), :notice => "Section has been successfully deleted"}
		 format.json {render :json=>{}}
              else
	         format.json {render :json=>report_error(@section)}
		 format.html {redirect_to return_to_location("/"), :error => "Section was not deleted"}
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

