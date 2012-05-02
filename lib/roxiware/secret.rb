module Roxiware
   module Secret
     def secret_authenticated?
       (cookies.has_key?(:secret) && !SecretPage.where(:secret => cookies[:secret]).first.nil?)
     end

     def require_secret
       if !secret_authenticated?
          redirect_to "/secret_pages"
       end
     end
   end
end
