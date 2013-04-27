
class Roxiware::ContactController < ApplicationController

  # POST a contact request
  def create
     begin
         # Get the mailer params
	 mailer_params = Roxiware::Param::Param.find(params[:mailer_params])
	 raise ActiveRecord::RecordNotFound if mailer_params.nil?

	 if mailer_params.h['response_subject'].present? && mailer_params.h['response_content'].present?
              Roxiware::ContactMailer.contact_mailer(mailer_params.h['response_content'].to_s, mailer_params.h['response_subject'].to_s, params).deliver
	 end

	 if mailer_params.h['response_subject'].present? && mailer_params.h['response_content'].present?
              Roxiware::ContactMailer.contact_mailer(mailer_params.h['response_content'].to_s, mailer_params.h['response_subject'].to_s, params).deliver
	 end

	 flash[:notice] = "Your request has been sent."
     rescue Exception => e
        puts e.message
        puts e.backtrace.join("\n")
        flash[:error] = e.message
     end
  end
end
