module Roxiware
  class SecretPageController < ApplicationController

    skip_before_filter :require_secret

    # GET /secret_pages
    # GET /secret_pages.json
    def index
      logger.debug("get secret page")
    end

    # PUT /secret_pages/1
    def authenticate
      if (params[:secret] != Roxiware.secret_page)
         flash[:error] = "Unknown secret"
      else
         logger.debug ("set cookie to " + params[:secret])
         cookies[:secret_page] = params[:secret]
      end
      redirect_to("/")
    end
  end
end
