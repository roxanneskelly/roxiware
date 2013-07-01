module Roxiware
    class ContactMailer < ActionMailer::Base
	default :from => "info@roxiware.com"

	def contact_mailer(mailer, to, subject, params)
	    mailer.gsub!(/\$([\w_]+|)/, '<%= \1 %>')
            subject.gsub!(/\$([\w_]+|)/, '%{\1}')
	    params[:from]  ||= Roxiware::Param::Param.application_param_val("system", "webmaster_email")
	    params[:site_title] = Roxiware::Param::Param.application_param_val("system", "title")
	    mail(:to => to, :subject => subject % params, :from=>"\" #{params[:site_title]} \" < #{params[:from]} >") do |format|
	        format.html { render :inline=>mailer, :locals=>params}
	    end
	end
    end
end