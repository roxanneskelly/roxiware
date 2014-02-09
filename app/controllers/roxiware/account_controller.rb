class Roxiware::AccountController < ApplicationController
  before_filter :authenticate_user!, :except=>[:authenticate, :edit_password, :send_reset_password, :do_reset_password]
  load_and_authorize_resource :except=>[:proxy_login, :edit, :edit_password, :update, :show, :new, :authenticate, :send_reset_password, :do_reset_password], :class=>"Roxiware::User"

  before_filter do
    @role = current_user.role if current_user.present?
    @role = "self" if current_user == @user
    @auth_server = AppConfig.omniauth_server || "/"
  end

  def index
    @users = @accounts
    @robots="noindex,nofollow"
    if @users.nil?
      @users = [current_user]
    end
  end

  # GET - show a user
  def show
    @robots="noindex,nofollow"
    if (params[:id] == "0")
      @user = Roxiware::User.find(current_user.id)
    else 
      @user = Roxiware::User.find(params[:id])
    end
    @role = "self" if current_user == @user
    raise ActiveRecord::RecordNotFound if @user.nil?

    authorize! :read, @user
    respond_to do |format|
      format.html { render }
      format.json { render :json => @user.ajax_attrs(@role) }
    end
  end

  # GET - return form for editing user
  def edit
    @robots="noindex,nofollow"
    if (params[:id] == 0)
      @user = Roxiware::User.find(current_user.id) unless current_user.nil?
    else 
      @user = Roxiware::User.find(params[:id])
    end
    @role = "self" if current_user == @user

    raise ActiveRecord::RecordNotFound if @user.nil?
    authorize! :edit, @user
    
    respond_to do |format|
      format.html { render :partial =>"roxiware/account/editform" }
      format.json { render :json => @user.ajax_attrs(@role) }
    end
  end

  # GET - return form for new user creation
  def new
    @robots="noindex,nofollow"
    authorize! :create, Roxiware::User
    @user = Roxiware::User.new({:role=>"guest"}, :as=>@role )
    @user.build_person({}, :as=>@role)

    respond_to do |format|
        format.html { render :partial =>"roxiware/account/editform" }
        format.json { render :json => @user.ajax_attrs(@role) }
    end
  end

  # POST - create a user
  def create
    @robots="noindex,nofollow"
    authorize! :create, Roxiware::User
    @user = Roxiware::User.new
    @user.build_person
    @user.person.bio = ""
    @user.person.role = params[:user][:role] if params.has_key?("role")
    respond_to do |format|
      @user.assign_attributes(params[:user], :as=>current_user.role)
      if !@user.save
         format.html { redirect_to "/", :notice=>flash_from_object_errors(@user) } 
         format.json { render :json=>report_error(@user)}
      else
         @user.reload
         @user.person.user_id = @user.id
	 @user.save
         format.json { render :json => @user.ajax_attrs(@role) }
         format.html { redirect_to "/", :notice=>"User successfully created."}
      end
    end
  end

  # PUT - update a user
  def update
    @robots="noindex,nofollow"
    if (params[:id] == 0)
      @user = Roxiware::User.find(current_user.id)
    else 
      @user = Roxiware::User::find(params[:id])
    end
    @role = "self" if current_user == @user
    raise ActiveRecord::RecordNotFound if @user.nil?
    authorize! :edit, @user
    update_params = params
    if params.has_key?("user")
      update_params=params["user"]
    end
    if (@role == "self") || update_params[:password].blank?
      update_params.delete(:password)
      update_params.delete(:password_confirmation) if update_params[:password_confirmation].blank?
    end

    if(current_user.role == "super")
        @user.auth_services.destroy_all
	auth_service_info = params[:user][:auth_services]
	auth_service_info.each do |provider, service_info|
	    if(service_info[:present].to_i)
	        new_service = @user.auth_services.build
		new_service.provider = provider
		new_service.uid = service_info[:uid]
		new_service.save!
	    end
	end
    end

    respond_to do |format|
      @user.assign_attributes(update_params, :as=>current_user.role)
      if !@user.save
         format.html { redirect_to "/", :notice=>flash_from_object_errors(@user) } 
         format.json { render :json=>report_error(@user)}
      else
	 flash[:notice]="Successfully updated."
         format.json { render :json => @user.ajax_attrs(@role)}
         if update_params.has_key?("password")
             format.html { redirect_to "/", :notice=>"User successfully updated.  You must log in again."}
	 else
	     format.html { redirect_to "/",  :notice=>"User successfully updated" }
	 end
      end
    end
  end

  # GET - new login form
  def show_sign_in
    @robots="noindex,nofollow"
    respond_to do |format|
      format.html { render :partial =>"devise/sessions/login" }
    end
  end

  # POST - send password reset request
  def send_reset_password
      errors = []
      find_params = Hash[params[:user].collect{|key, value| [key.to_sym, value]}].slice(*Devise.reset_password_keys)
      
      if(find_params.present?)
          user = Roxiware::User.where(find_params).first
      else
          raise Exception.new("Invalid Parameters")
      end
      errors = user.errors.collect{|attribute, error| [attribute.to_s().split('.')[-1], error.to_s()]} if user.present?

      # if user can't be found, or no valid find_params are passed, don't
      # return an error message, as that would allow an attacker to scan
      # for valid accounts

      if(user.present? && errors.blank?)
          auth_service = user.auth_services.find_by_provider('roxiware')
          if (auth_service.present?)
	      # proxy to the auth server
	      uri = URI(URI.join(@auth_server, account_reset_password_path).to_s+".json?"+{:user=>find_params}.to_param)
	      http = Net::HTTP.new(uri.host, uri.port)
	      if uri.scheme == 'https'
	          http.use_ssl = true
	          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	      end
	      req = Net::HTTP::Post.new(uri.to_s, initheader = { 'Content-Type' => 'text/plain'})
	      response = http.request(req)
	      if(response.present?)
	          case response.code.to_i
                      when 200
	                  result_data = {}
	                  result_data = JSON.parse(response.body)
		          if(result_data.present?)
                              errors.concat(result_data['error']) if result_data['error'].present?
		          else
		              errors << ["exception", "Bad response from server."]
		          end
                      else
		          errors << ["exception", "Bad response from server: #{response.code.to_i}"]
                  end
              else
                  errors << ["exception", "No response from server"]
	      end
	      
          else
              user.send_reset_password_instructions
          end
      end
      respond_to do |format|
          if(errors.present?) 
	      format.json { render :json=>{:error=>errors }}
          else
              format.json { render :json => {:success=>true} }
          end
      end
  end


  # PUT 
  def do_reset_password
      errors = []
      @user = Roxiware::User.reset_password_by_token(params[:user].slice(:password, :password_confirmation).merge({:reset_password_token=>params[:reset_password_token]}))
      @role = "self"
      errors.concat(@user.errors.collect{|attribute, error| [attribute.to_s().split('.')[-1], error.to_s()]})
      respond_to do |format|
	  if errors.present?
	      format.json { render :json=>{:error=>errors }}
	  else
	      sign_in(:user, @user)
	      format.json { render :json=>@user.ajax_attrs(@role)}
	  end
       end
  end
  

  # GET - return form for editing the current users password
  def edit_password
    @robots="noindex,nofollow"
    if(params[:reset_password_token].present?)
        @reset_password_token = params[:reset_password_token] if params[:reset_password_token].present?
    else
        @user = Roxiware::User.find(current_user.id) unless current_user.nil?
        raise ActiveRecord::RecordNotFound if @user.nil?
        authorize! :edit, @user
    end
    respond_to do |format|
        format.html { render :partial =>"roxiware/account/change_password" }
    end
  end


  # the user is linked to a roxiware auth server, so all password updates should go to that server
  def _update_remote_password(user)

      errors = []
      begin
	  # attempt to update the password on the auth server
	  uri = URI(URI.join(@auth_server, account_update_password_path).to_s+".json?"+{:user=>params[:user].slice(:current_password, :password, :password_confirmation)}.to_param)
	  http = Net::HTTP.new(uri.host, uri.port)
	  if uri.scheme == 'https'
	      http.use_ssl = true
	      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	  end
	  req = Net::HTTP::Put.new(uri.to_s, initheader = { 'Content-Type' => 'text/plain'})
	  req.basic_auth @user.username, params[:user][:current_password]
	  req.body = ""
	  password_update_response = http.request(req)

	  if(password_update_response.present?)
	      case password_update_response.code.to_i
                  when 200
	              result_data = {}
	              result_data = JSON.parse(password_update_response.body)
		      if(result_data.present?)
                          errors.concat(result_data['error']) if result_data['error'].present?
		      else
		          errors << ["exception", "Bad response from server."]
		      end
                  when 401
		      errors << ["current_password", "Current password is invalid."]
                  else
		      errors << ["exception", "Bad response from server: #{password_update_response.code.to_i}"]
              end
          else
              errors << ["exception", "No response from server"]
	  end
      rescue Exception=>e
          puts e.backtrace.join("\n")
          errors << ["exception", e.message]
      end
  end

  # PUT - update a users password
  def update_password
    @robots="noindex,nofollow"
    @user = current_user
    @role = "self"
    errors = []
    authorize! :edit, @user

    auth_service = @user.auth_services.find_by_provider('roxiware')
    if(auth_service.present?)
        # proxy the password update to the parent server
        errors = _update_remote_password(@user)
    else
        # update locally
        update_params = params
        if params.has_key?(:user)
            update_params=Hash[params[:user].collect{|name, value| [name.to_sym, value]}]
        end

        errors << ["current_password", "Current password is invalid."] unless@user.valid_password?(update_params[:current_password])
	if errors.blank?
            @user.update_attributes(update_params, :as=>@role)
	    @user.save
	    errors.concat(@user.errors.collect{|attribute, error| [attribute.to_s().split('.')[-1], error.to_s()]})
	end
    end
    respond_to do |format|
        if errors.present?
	    format.json { render :json=>{:error=>errors }}
	else
            sign_in(:user, @user)
	    format.json { render :json=>@user.ajax_attrs(@role)}
	end
     end
  end

  # GET - check if a user can be authenticated
  def authenticate
      if signed_in?
          render(:nothing => true, :status=>:ok)
      else
          render(:nothing => true, :status=>:unauthorized)
      end
  end

  # DELETE - delete a user
  def destroy
    @robots="noindex,nofollow"
    @user = @account
    respond_to do |format|
      if @user == current_user 
        format.json { render :json=>{:error=>[nil, "You cannot delete yourself"]}}
      end
      @user.person.user_id=nil if @user.person.present?
      @user.person.save if @user.person.present?
      if !@user.destroy
        format.json { render :json=>report_error(@user)}
      else
        format.json { render :json=>{}}
      end
    end
  end
end
