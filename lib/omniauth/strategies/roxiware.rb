require 'omniauth'
require 'net/http'
module OmniAuth
    module Strategies
	class Roxiware
	    include OmniAuth::Strategy

            option :fields, [:username]
	    option :uid_field, :username
	    option :auth_server, nil

	    uid do
	      request.params['user'][options.uid_field.to_s]
	    end

	    info do
	      options.fields.inject({}) do |hash, field|
		hash[field] = request.params['user'][field]
		hash
	      end
	    end

            def request_phase
            end

            def callback_phase
	        if request.params['user'].present? && request.params['user']['username'].present?
	            return fail!(:internal_server_error) if options.auth_server.blank?
		    # attempt to find user locally, and determine if there's a auth_service entry
		    user = ::Roxiware::User.find_by_username(request.params['user']['username'])
		    return fail!(:not_found) if user.blank?
                    auth_service = user.auth_services.find_by_provider('roxiware')
		    if !auth_service
		         # user doesn't auth with the auth server, so return notification that 
                         # service is unavailable and we should try local auth
                         return fail!(:service_unavailable)
		    else
		        uri = URI(options.auth_server)
			uri.path = "/account/authenticate"
		        http = Net::HTTP.new(uri.host, uri.port)
		        if uri.scheme == 'https'
			     http.use_ssl = true
			     http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		         end
		         req = Net::HTTP::Get.new(uri.to_s)
		         req.basic_auth request.params['user']['username'], request.params['user']['password']
		         authentication_response = http.request(req)

                         return fail!(:internal_server_error) if !authentication_response
                         return fail!(:invalid_credentials) if authentication_response.code.to_i == 401
                         return fail!(authentication_response.code) if authentication_response.code.to_i != 200
		    end
		end
		super
            end

	end
    end
end
