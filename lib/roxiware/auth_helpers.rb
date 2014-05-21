module Roxiware
    module AuthHelpers
        # AuthUserToken identifies a pre-authorized user
        class AuthUserToken
            def initialize(auth_user_info_or_options={})
                @verifier = ActiveSupport::MessageVerifier.new(AppConfig.auth_state_verify_key)
                if auth_user_info_or_options.class == String
                    # unpack and validate the auth state
                    verified_params = @verifier.verify(auth_user_info_or_options)
                    raise Exception.new("Auth User Info unpacking was unverified") if verified_params.nil?
                    @expires,@auth_kind,@uid,@full_name,@thumbnail_url,@email,@url = verified_params
                else
                    # generate an auth state from params
                    @expires = nil
                    @uid = auth_user_info_or_options[:uid] || ""
                    @full_name = auth_user_info_or_options[:full_name] || @uid
                    @thumbnail_url = auth_user_info_or_options[:thumbnail_url] || ""
                    @email = auth_user_info_or_options[:email] || ""
                    @url = auth_user_info_or_options[:url] || ""
                    @auth_kind = (auth_user_info_or_options[:auth_kind] || "facebook").to_s
                end
            end

            def token_attributes
                {:email=>email, :name=>full_name, :thumbnail_url=>thumbnail_url, :url=>url, :uid=>uid, :authtype=>auth_kind}
            end

            def expires
                @expires || 1.week.from_now
            end

            def expired?
                (expires < Time.now)
            end

            def email
                @email
            end

            def full_name
                @full_name
            end

            def thumbnail_url
                @thumbnail_url
            end

            def url
                @url
            end

            def uid
                @uid
            end

            def auth_kind
                @auth_kind
            end

            def get_state
                @expires=1.week.from_now
                CGI::escape(@verifier.generate([@expires, @auth_kind, @uid, @full_name, @thumbnail_url, @email, @url]))
                @verifier.generate([@expires, @auth_kind, @uid, @full_name, @thumbnail_url, @email, @url])
            end
        end

        # code to deal with an auth state object, which is used
        # to store the host redirect, validate the auth request properly came
        # from a Roxiware site, etc.
        class AuthState
            def initialize(auth_state_or_options={})

                @verifier = ActiveSupport::MessageVerifier.new(AppConfig.auth_state_verify_key)
                if auth_state_or_options.class == String
                    # unpack and validate the auth state

                    verified_params = @verifier.verify(auth_state_or_options)
                    expires = verified_params.shift if verified_params.present?
                    verified_params = nil if expires.present? && (expires < Time.now)
                    raise Exception.new("Auth State unpacking was unverified or expired") if verified_params.nil?
                    # Indicates whether this is a proxy request or a full login request.
                    # proxy requests simply validate that the oauth was valid, but don't
                    # check against the user account
                    @proxy = verified_params.shift

                    # After authentication, we'll redirect to the appropriate URI based on
                    # this host and port
                    @host_with_port = verified_params.shift
                    @auth_kind = verified_params.shift
                else
                    # generate an auth state from params

                    @proxy = auth_state_or_options[:proxy] || false
                    @host_with_port = auth_state_or_options[:host_with_port] || ""
                    @auth_kind = (auth_state_or_options[:auth_kind] || "facebook").to_s
                end
            end

            def proxy?
                return @proxy
            end

            def host_with_port
                @host_with_port
            end

            def auth_kind
                @auth_kind
            end

            def redirect_uri(provider)
                if(!@proxy)
                    "http://#{@host_with_port}#{user_omniauth_callback(provider)}"
                else
                    # if we're doing a proxy, we'll simply return packaged info to the caller
                    # containing interesting bits
                    nil
                end
            end

            def get_state
                @verifier.generate([1.day.from_now, @proxy, @host_with_port, @auth_kind])
            end
        end
    end
end
