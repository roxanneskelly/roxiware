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
	   page_identifier << ""
           @page = Roxiware::Layout::PageLayout.where(:layout_id=>@layout.id, :controller=>page_identifier[0], :action=>page_identifier[1]).first
	   raise ActiveRecord::RecordNotFound if @page.nil?
	   authorize! :read, @page
           respond_to do |format|
	     format.html { render :partial => "roxiware/shared/edit_page_layout_form" }
	   end
       end

       def update
           page_identifier = params[:id].split("#")
	   page_identifier << ""
           @page = Roxiware::Layout::PageLayout.where(:layout_id=>@layout.id, :controller=>page_identifier[0], :action=>page_identifier[1]).first
	   raise ActiveRecord::RecordNotFound if @page.nil?
	   authorize! :update, @page
	   respond_to do |format|
	       if @page.update_attributes(params, :as=>@role)
	          @page.params.each do |page_param|
		     if params[page_param.name.to_sym].present?
		        page_param.value = params[page_param.name.to_sym]
			page_param.save!
		     end
		  end
		  refresh_layout
		  format.html { redirect_to return_to_location("/"), :notice => 'layout page was successfully updated.' }
		  format.json { render :json => @page.ajax_attrs(@role) }
	       else
		  format.html { redirect_to return_to_location("/"), :alert => 'Failure updating page layout.' }
		  format.json { render :json=>report_error(@page)}
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

