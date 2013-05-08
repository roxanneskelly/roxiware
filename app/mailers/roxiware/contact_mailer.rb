module Roxiware
    class ContactMailer < ActionMailer::Base
	default :from => "info@roxiware.com"

	def contact_mailer(mailer, to, subject, params)
	    params[:from]  ||= Roxiware::Param::Param.application_param_val("system", "webmaster_email")
	    mail(:to => to, :subject => subject, :from=>params[:from]) do |format| 
	        format.html { render :inline=>mailer, :locals=>{:params=>params}}
	    end
	end
    end
end