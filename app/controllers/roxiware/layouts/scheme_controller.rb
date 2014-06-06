module Roxiware
    module Layouts
        class SchemeController < ApplicationController
            before_filter :_load_role, :unless=>[]
            skip_after_filter :store_location
            def update
                errors = []
                ActiveRecord::Base.transaction do
                    begin
                        @layout = Roxiware::Layout::Layout.where(:guid=>params[:layout_id]).first
                        @scheme = @layout.get_param("schemes").h[params[:id]] if @layout.get_param("schemes").present?
                        params[:custom_settings].each do |name, value|
                            @scheme.get_param("params").set_param(name, value)
                        end
                        @layout.reset_custom_settings
                        refresh_layout
                    rescue Exception => e
                        logger.error e.message
                        logger.error e.backtrace.join("\n")
                        errors << ["exception", e.message]
                    end
                end
                respond_to do |format|
                    result = errors.present? ? { :error=>errors } : { :success=>true }
                    puts "RESULT " + result.inspect
                    format.json {  render :json=>result }
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
