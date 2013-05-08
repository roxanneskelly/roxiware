
class Roxiware::ContactController < ApplicationController

  # POST a contact request
  def create
     begin
         # Get the mailer params
	 mailer_params = Roxiware::Param::Param.find(params[:mailer_params])
	 raise ActiveRecord::RecordNotFound if mailer_params.nil?

	 if mailer_params.h['response'].present? && mailer_params.h['response'].h['content'].present? && mailer_params.h['response'].h['subject'].present?
              Roxiware::ContactMailer.contact_mailer(mailer_params.h['response'].h['content'].to_s, params[:email], mailer_params.h['response'].h['subject'].to_s, params).deliver
	 end
	 if mailer_params.h['notification'].present? && mailer_params.h['notification'].h['content'].present? && mailer_params.h['notification'].h['subject'].present?
              Roxiware::ContactMailer.contact_mailer(mailer_params.h['notification'].h['content'].to_s, Roxiware::Param::Param.application_param_val("system", "webmaster_email"), mailer_params.h['notification'].h['subject'].to_s+" : "+params[:email], params).deliver
	 end
	 flash[:notice] = "Your request has been sent."
     rescue Exception => e
        puts e.message
        puts e.backtrace.join("\n")
        flash[:error] = e.message
     end
     redirect_back_or_default("/")
  end
end
