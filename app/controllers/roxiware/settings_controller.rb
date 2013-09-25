module Roxiware
  class SettingsController < ApplicationController
       skip_after_filter :store_location

       # settings edit page
       def show
          @application = params[:id]
          @settings = Hash[Roxiware::Param::Param.application_params(params[:id]).select{|param| can? :edit, param}.collect{|param| [param.name, param]}]
	  edit_file_root = params[:id]
	  edit_file_root = "default" unless File.file?("#{Roxiware::Engine.root}/app/views/roxiware/settings/_editform_#{edit_file_root}.html.erb")
          respond_to do |format|
	     format.html {render :partial => "roxiware/settings/editform_#{edit_file_root}"}
	     format.json {render :json =>settings}
	  end
       end

       def update
         setting_params = Roxiware::Param::Param.application_param_hash(params[:id])
         params[params[:id]].each do |key, value|
	     if setting_params[key] && can?(:edit, setting_params[key])
	          Roxiware::Param::Param.set_application_param(params[:id], key, setting_params[key].description_guid, value)
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