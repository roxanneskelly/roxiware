require 'msgpack'
module Roxiware
    module AuthHelpers

        class SafeToken
            def initialize(password, options={})
                @password = password
            end

            def pack(data, options={ })
                salt = SecureRandom.random_bytes(64)
                key = ActiveSupport::KeyGenerator.new(@password).generate_key(salt)
                crypt = ActiveSupport::MessageEncryptor.new(key)
                expiry = options[:expiry].present? ? options[:expiry].to_s : ""
                decrypted_message = [expiry, data]
                encrypted_data = crypt.encrypt_and_sign(decrypted_message.to_msgpack)
                CGI::escape(encrypted_data + "," + Base64.encode64(salt).encode64(salt).gsub(/\n/,''))
            end

            def unpack(message, options={})
                encrypted_data,salt = message.split(",")
                key = ActiveSupport::KeyGenerator.new(@password).generate_key(Base64.decode64(salt))
                crypt = ActiveSupport::MessageEncryptor.new(key)
                expiry,data = MessagePack.unpack(crypt.decrypt_and_verify(encrypted_data))
                raise Exception.new("Your session has expired.  Please restart your sign-up.") if expiry.present? && (Time.zone.parse(expiry) < Time.now)
                if(options[:include_expiry])
                    [data, expiry]
                else
                    data
                end
            end
        end

        # AuthUserToken identifies a pre-authorized user
        class AuthUserToken
            def initialize(auth_user_info_or_options={})
                if auth_user_info_or_options.class == String
                    # unpack and validate the auth state
                    data, @expiry = Roxiware::AuthHelpers::SafeToken.new(AppConfig.auth_state_verify_key).unpack(auth_user_info_or_options, :include_expiry=>true)
                    @auth_kind,@uid,@full_name,@thumbnail_url,@email,@url = data
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
                Roxiware::AuthHelpers::SafeToken.new(AppConfig.auth_state_verify_key).pack([@auth_kind, @uid, @full_name, @thumbnail_url, @email, @url], :expiry=>@expires)
            end
        end

        # code to deal with an auth state object, which is used
        # to store the host redirect, validate the auth request properly came
        # from a Roxiware site, etc.
        class AuthState
            def initialize(auth_state_or_options={})
                puts "INITIALIZE Auth State " + auth_state_or_options.inspect
                if auth_state_or_options.class == String
                    # unpack and validate the auth state

                    verified_params, @expiry = Roxiware::AuthHelpers::SafeToken.new(AppConfig.auth_state_verify_key).unpack(auth_state_or_options, :include_expiry=>true)
                    @proxy, @host_with_port, @auth_kind = verified_params
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
                @expires=1.day.from_now
                Roxiware::AuthHelpers::SafeToken.new(AppConfig.auth_state_verify_key).pack([@proxy, @host_with_port, @auth_kind], :expiry=>@expires)
            end
        end
    end
end
