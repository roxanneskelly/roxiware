# omniauth handling.
# copied from https://gist.github.com/schleg/993566

module Roxiware
    class OmniauthCallbacksController < ApplicationController

        def facebook
            oauthorize :facebook
        end

        def twitter
            oauthorize :twitter
        end

        def google
            oauthorize :google
        end

        def roxiware
            oauthorize :roxiware
        end

        def failure
            puts "FAIL"
	    puts env['omniauth.error.strategy'].inspect
            # Fall back and try native roxiware auth if the provider is roxiware
	    if env['omniauth.error.strategy'].name == "roxiware" 
	        puts "auth failure while looking up user with roxiware omniauth strategy, attempting local auth with " + request.params['user']['username']
		@user = Roxiware::User.find_for_authentication(:username => request.params['user']['username'])
		if @user.present?
		   puts "user present"
		   return sign_in_and_redirect @user, :event => :authentication if @user.valid_password?(request.params['user']['password'])
		   puts "couldn't authenticate"
		end
	    end
	    render :nothing => true, :status=>:unauthorized
        end

    private
        def oauthorize(kind)
            puts "OAUTH"
	    if signed_in?
                flash[:notice] = "Already signed in as #{current_user.username}"
            else
	       @user = find_for_ouath(kind, env["omniauth.auth"])
	       if @user
                   flash[:notice] = "Logged in with #{kind.to_s.titleize}"
		   session["devise.#{kind.to_s}_data"] = env["omniauth.auth"]
		   sign_in_and_redirect @user, :event => :authentication
               else
                   flash[:error] = "Unable to sign in with #{kind.to_s.titleize}"
		   render :nothing => true, :status=>:unauthorized
               end
	    end
        end

	def find_for_ouath(provider, access_token)
	    user,uid,email = nil,nil,nil 
	    case provider
	    when :facebook
	        uid = access_token['uid']
	        username = access_token['extra']['raw_info']['username']
	        email = access_token['extra']['raw_info']['email']
	    when :twitter
	        uid = access_token['extra']['user_hash']['id']
	        name = access_token['user_info']['name']
            when :roxiware
                username = access_token['uid']
	    else
	        raise 'Provider #{provider} not handled'
	    end
	    user = find_for_oauth_by_uid(uid, provider) if uid.present?
	    user = find_for_oauth_by_uid(username, provider) if user.blank? && username.present?
	    user = find_for_oauth_by_email(email, provider) if user.blank? && email.present?
            user
	end

	def find_for_oauth_by_uid(uid, provider)
	    puts "FINDING #{uid} for #{provider}"
	    user = nil
	    auth = Roxiware::AuthService.find_by_provider_and_uid(provider, uid)
            if auth
                puts "found"
	        user = auth.user
                puts "user is #{user.inspect}"
            end
	    user
	end

	def find_for_oauth_by_email(email, provider)
	    Roxiware::User.find_by_email(email)
	end
    end
end