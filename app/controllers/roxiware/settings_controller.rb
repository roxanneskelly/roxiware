module Roxiware
  class SettingsController < ApplicationController

       skip_after_filter :store_location
       # settings edit page
       def show
          setting_params = Roxiware::Param::Param.includes(:param_description).where(:param_object_type => nil)
	  @settings = {}
	  setting_params.each do |setting_param|
	     setting_param_name = setting_param.param_class
	     @settings[setting_param_name] ||= {}
	     @settings[setting_param_name][setting_param.name] = setting_param
	  end
	  
          respond_to do |format|
	     format.html {render :partial => "roxiware/shared/edit_settings_form"}
	     format.json {render :json =>settings}
	  end
       end

       def update
         setting_params = Roxiware::Param::Param.where(:param_object_type => nil)
         setting_params.each do |setting_param|
	    setting_param_name = (setting_param.param_class + "/" + setting_param.name).to_sym
            if params[setting_param.param_class].present? && params[setting_param.param_class][setting_param.name].present?
	       if(setting_param.value != params[setting_param.param_class][setting_param.name])
                   setting_param.value = params[setting_param.param_class][setting_param.name]
	           setting_param.save!
               end
	    end
         end
         Roxiware::Param::Param.refresh_application_params
	 refresh_layout
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