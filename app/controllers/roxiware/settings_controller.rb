module Roxiware
  class SettingsController < ApplicationController
       skip_after_filter :store_location

       # settings edit page
       def show
          @settings = Hash[Roxiware::Param::Param.application_params(params[:id]).select{|param| can? :edit, param}.collect{|param| [param.name, param]}]
          respond_to do |format|
	     format.html {render :partial => "roxiware/settings/editform_#{params[:id]}"}
	     format.json {render :json =>settings}
	  end
       end

       def update
         setting_params = Roxiware::Param::Param.application_params(params[:id])
         setting_params.each do |setting_param|
	    next if(cannot? :edit, setting_param)
	    
            if params[params[:id]][setting_param.name].present?
	       Roxiware::Param::Param.set_application_param(params[:id], setting_param.name, setting_param.description_guid, params[params[:id]][setting_param.name])
	    end
         end
	 refresh_layout	
	 run_layout_setup
         respond_to do |format|
            format.html { redirect_to return_to_location("/"), :notice => 'Settings were successfully updated.' }
            format.json { render :json => {} }
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