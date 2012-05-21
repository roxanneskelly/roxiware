module Roxiware
  module ApplicationControllerHelper
    private 
    def after_sign_in_path_for(resource_or_scope)
      "/"
    end
    def after_sign_out_path_for(resource_or_scope)
      "/"
    end
  end
end
