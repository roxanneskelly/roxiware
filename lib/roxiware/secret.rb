module Roxiware
   module Secret
     def secret_authenticated?
       logger.debug "checking require secret " + cookies[:secret_page].to_s + " " + Roxiware.secret_page.to_s
       
       Roxiware.secret_page.nil? || (cookies[:secret_page] == Roxiware.secret_page)
     end

     def require_secret
       if !secret_authenticated?
          redirect_to "/secret_page"
       end
     end
   end
end
