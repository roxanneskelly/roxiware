module Roxiware
  module Layouts
    class PageController < ApplicationController
       before_filter :_load_role, :unless=>[]
       skip_after_filter :store_location
       
       before_filter do
	   @layout = Roxiware::Layout::Layout.where(:guid=>params[:layout_id]).first
	   raise ActiveRecord::RecordNotFound if @layout.nil?
	   authorize! :read, @layout
       end

       # list all layouts
       def index
          pages = Roxiware::Layout::PageLayout.all
	  @pages = []
	  pages.each do |page|
  	     authorize! :read, page
	     @pages << {:controller=>page[:controller], :action=>page[:action], :name=>page[:name]}
	  end
          respond_to do |format|
	     format.json {render :json =>@pages}
	  end
       end
       
       def show
           page_identifier = params[:id].split("#")
	   controller = page_identifier[0] || ""
	   action = page_identifier[1] || ""
           @page = Roxiware::Layout::PageLayout.where(:layout_id=>@layout.id, :controller=>controller, :action=>action).first
	   raise ActiveRecord::RecordNotFound if @page.nil?
	   authorize! :read, @page
           respond_to do |format|
	     format.html { render :partial => "roxiware/shared/edit_page_layout_form" }
	   end
       end

       def update
           page_identifier = params[:id].split("#")
	   controller = page_identifier[0] || ""
	   action = page_identifier[1] || ""
           @page = Roxiware::Layout::PageLayout.where(:layout_id=>@layout.id, :controller=>controller, :action=>action).first
	   raise ActiveRecord::RecordNotFound if @page.nil?
	   authorize! :update, @page
	   success = true
           ActiveRecord::Base.transaction do
	      begin
	         if params[:params].present?
	            @page.params.each do |page_param|
		       if params[:params][page_param.name.to_sym].present?
		          page_param.value = params[:params][page_param.name.to_sym]
			  page_param.save!
		       end
		    end
		 end
		 if !@page.update_attributes(params, :as=>@role)
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
		  format.json { render :json => @layout.ajax_attrs(@role) }
	       else
		  format.html { redirect_to return_to_location("/"), :alert => 'Failure updating layout.' }
		  format.xml  { head :fail }
		  format.json { render :json=>report_error(@layout)}
	       end
	   end
       end

       def create
	   authorize! :create, Roxiware::Layout::PageLayout
           page_params = params[:params]
	   
	   identifier = page_params[:url_identifier].split("#")
	   controller = identifier[0] || ""
	   action = identifier[1] || ""

	   @page = @current_layout.page_layouts.build
	   if (page_params[:clone].present?)
	       print "CLONING PAGE\n"
               clone_page = Roxiware::Layout::PageLayout.find(page_params[:clone])
	       raise ActiveRecord::RecordNotFound if clone_page.nil?
	       @page.update_attributes(clone_page.attributes, :as=>nil)
	       clone_page.params.each do |page_param|
	          # NOTE, recursive params?
	          @page.params << page_param.dup
	       end
	   end
           @page.controller = controller
	   @page.action = action
	   success = true
           ActiveRecord::Base.transaction do
	      begin
	         if params[:params].present?
	            @page.params.each do |page_param|
		       if params[:params][page_param.name.to_sym].present?
		          page_param.value = params[:params][page_param.name.to_sym]
			  page_param.save!
		       end
		    end
		 end
		 if !@page.update_attributes(params, :as=>@role)
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
		  format.json { render :json => @page.ajax_attrs(@role) }
	       else
		  format.html { redirect_to return_to_location("/"), :alert => 'Failure updating layout.' }
		  format.xml  { head :fail }
		  format.json { render :json=>report_error(@layout)}
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

