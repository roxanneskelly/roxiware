class Roxiware::SecretPagesController < ApplicationController
  skip_before_filter :require_secret

  # GET /secret_pages
  # GET /secret_pages.json
  def index
    ::Devise.included_modules.each do |const_name|
        logger.debug(const_name)
    end
  end

  # PUT /secret_pages/1
  def authenticate
    @secret_page = SecretPage.where(:secret => params[:secret])

    if (@secret_page.nil?)
       flash[:error] = "Unknown secret"
    else
       cookies[:secret] = params[:secret]
    end
    redirect_to("/")
  end
end
