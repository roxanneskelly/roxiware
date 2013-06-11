require 'omniauth'
require 'net/http'
module OmniAuth
    module Strategies
	class Roxiware
	    include OmniAuth::Strategy

            option :fields, [:username]
	    option :uid_field, :username
	    option :auth_server, "http://customer.roxiware.com/account/authenticate"

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
		    puts "ATTEMPTING USER LOOKUP FOR #{request.params['user']['username']}"
		    # attempt to find user locally, and determine if there's a auth_service entry
		    user = ::Roxiware::User.find_by_username(request.params['user']['username'])
		    return fail!(:invalid_credentials) if user.blank?
		    puts "USER FOUND, looking for auth provider"
                    auth_service = user.auth_services.find_by_provider('roxiware')
		    if !auth_service
                         return fail!(:invalid_credentials)
		    else
		        puts "AUTH SERVICE IS #{auth_service.inspect}"
		        uri = URI(options.auth_server)
			puts "URI IS #{uri.inspect}"
		        http = Net::HTTP.new(uri.host, uri.port)
		        if uri.scheme == 'https'
			     http.use_ssl = true
			     http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		         end
		         req = Net::HTTP::Get.new(uri.to_s)
		         req.basic_auth request.params['user']['username'], request.params['user']['password']
		         authentication_response = http.request(req)
			 puts "RESPONSE " + authentication_response.code.to_s

                         return fail!(:invalid_credentials) if !authentication_response
                         return fail!(:invalid_credentials) if authentication_response.code.to_i >= 400
			 puts "RETURN SUCCESS"
		    end
		end
		super
            end

	end
    end
end
