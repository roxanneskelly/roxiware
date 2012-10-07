module Roxiware
  module Layouts
    class LayoutController < ApplicationController
       before_filter :_load_role, :unless=>[]
       skip_after_filter :store_location

       # list all layouts
       def index
          layouts = Roxiware::Layout::Layout.all
	  @layouts = []
	  layouts.each do |layout|
  	     authorize! :read, layout
	     @layouts << {:guid=>layout[:guid], :name=>layout[:name]}
	  end
          respond_to do |format|
	     format.json {render :json =>@layouts}
	  end
       end
       
       def show
           @layout = Roxiware::Layout::Layout.where(:guid=>params[:id]).first
	   raise ActiveRecord::RecordNotFound if @layout.nil?
	   authorize! :read, @layout
           respond_to do |format|
	     format.html { render :partial => "roxiware/shared/edit_layout_form" }
	   end
       end

       def update
           @layout = Roxiware::Layout::Layout.where(:guid=>params[:id]).first
	   raise ActiveRecord::RecordNotFound if @layout.nil?
	   authorize! :update, @layout
	   success = true
           ActiveRecord::Base.transaction do
	      begin
	         if params[:params].present?
	            @layout.params.each do |layout_param|
		       if params[:params][layout_param.name.to_sym].present?
		          layout_param.value = params[:params][layout_param.name.to_sym]
			  instance_param.save!
		       end
		    end
		 end
		 if !@layout.update_attributes(params, :as=>@role)
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

     private
       def _load_role
	   @role = "guest"
	   @role = current_user.role unless current_user.nil?
	   @person_id = (current_user && current_user.person)?current_user.person.id : -1
       end
    end
  end
end