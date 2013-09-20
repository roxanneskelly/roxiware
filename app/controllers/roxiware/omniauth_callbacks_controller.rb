require 'uri'
# omniauth handling.
# copied from https://gist.github.com/schleg/993566

module Roxiware
    class OmniauthCallbacksController < ApplicationController

        def facebook
	    (params['is_proxy'] == "true") ? auth_results(:facebook) : oauthorize(:facebook)
        end

        def twitter
	    (params['is_proxy'] == "true") ? auth_results(:twitter) : oauthorize(:twitter)
        end

        def google
            oauthorize :google
        end

        def roxiware
            oauthorize :roxiware
        end

	# if it's a login, and not a proxy, redirect to the callback provider
	def authproxy
            @auth_info = env["omniauth.auth"]["info"]
	    @login_url = @auth_info['login_url']
	    redirect_to @login_url
	end

        def failure
            # Fall back and try native roxiware auth if the provider is roxiware
	    if env['omniauth.error.strategy'].name == "roxiware" && env['omniauth.error.type'] == :service_unavailable
		@user = Roxiware::User.find_for_authentication(:username => request.params['user']['username'])

		# return unauthorized if user can't be found so we don't leak the fact that the
                # user doesn't exist.
	        return render :nothing => true, :status=>:unauthorized if @user.blank?
		if @user.valid_password?(request.params['user']['password'])
                   flash[:notice] = "Successfully signed in"
		   return sign_in_and_redirect @user, :event => :authentication
		else
	           return render :nothing => true, :status=>:unauthorized
		end
            end
	    if (env['omniauth.error.type'] == :invalid_credentials) || (env['omniauth.error.type'] == :not_found)
	        render :nothing => true, :status=>:unauthorized
            else
	       render :nothing => true, :status=>:internal_server_error
            end
        end

    private

	def auth_results(kind)
	    access_token = env["omniauth.auth"]
	    
	    auth_info = {}
	    case kind
	        when :facebook
		    raw_info = access_token["extra"]["raw_info"]
                    auth_info = {:uid => raw_info["username"],
                                 :auth_kind => 'facebook',
                                 :email => raw_info['email'],
                                 :full_name => raw_info['name'],
                                 :thumbnail_url => "http://graph.facebook.com/#{raw_info['username']}/picture?type=square",
                                 :url => raw_info['link']}
		    auth_token = Roxiware::AuthHelpers::AuthUserToken.new(auth_info)
		    auth_info[:auth_token] = auth_token.get_state
		    auth_info[:expires] = auth_token.expires.to_i
	        when :twitter
		    raw_info = access_token["extra"]["raw_info"]
		    info = access_token["info"]
                    auth_info = {:uid => info["nickname"],
                                 :auth_kind => 'twitter',
                                 :email => '',
                                 :full_name => info['name'],
                                 :thumbnail_url => info['image'],
                                 :url => info['urls']['Twitter']}
		    auth_token = Roxiware::AuthHelpers::AuthUserToken.new(auth_info)
		    auth_info[:auth_token] = auth_token.get_state
		    auth_info[:expires] = auth_token.expires.to_i
            end
	    render :inline=>"<script>localStorage.roxiwareAuthInfo='#{auth_info.to_json}'; window.close();</script>"
	end


        def oauthorize(kind)
	    if signed_in?
                flash[:notice] = "Already signed in as #{current_user.username}"
            else
	       @user = find_for_ouath(kind, env["omniauth.auth"])
	       if @user.present?
                   flash[:notice] = "Logged in with #{kind.to_s.titleize}"
		   session["devise.#{kind.to_s}_data"] = env["omniauth.auth"]
                   if kind == :roxiware
		       sign_in_and_redirect @user, :event => :authentication
		   else
		       # on 3rd party omniauth servers, render the code that 
		       # reloads the parent window
		       sign_in(@user)
	               auth_results(kind)
		   end
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
	        uid = access_token['info']['nickname']
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
	    user = nil
	    auth = Roxiware::AuthService.find_by_provider_and_uid(provider, uid)
            if auth
	        user = auth.user
            end
	    user
	end

	def find_for_oauth_by_email(email, provider)
	    Roxiware::User.find_by_email(email)
	end
    end
end