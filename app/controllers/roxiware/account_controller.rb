class Roxiware::AccountController < ApplicationController
  before_filter :authenticate_user!, :except=>[:authenticate]
  load_and_authorize_resource :except=>[:edit, :update, :show, :new, :authenticate], :class=>"Roxiware::User"

  before_filter do
    @role = current_user.role if current_user.present?
    @role = "self" if current_user == @user
    @auth_server = AppConfig.omniauth_server || "/"
  end

  # GET - enumerate user
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
      if !@user.update_attributes(params[:user], :as=>current_user.role)
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

    respond_to do |format|
      if !@user.update_attributes(update_params, :as=>current_user.role)
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
  def sign_in
    @robots="noindex,nofollow"
    respond_to do |format|
      format.html { render :partial =>"devise/sessions/login" }
    end
  end

  # GET - return form for editing the current users password
  def edit_password
    @robots="noindex,nofollow"
    @user = Roxiware::User.find(current_user.id) unless current_user.nil?
    raise ActiveRecord::RecordNotFound if @user.nil?
    authorize! :edit, @user
    respond_to do |format|
        format.html { render :partial =>"roxiware/account/change_password" }
    end
  end

  # PUT - update a users password
  def update_password
    @robots="noindex,nofollow"
    @user = Roxiware::User.find(current_user.id)
    @role = "self"
    raise ActiveRecord::RecordNotFound if @user.nil?
    authorize! :edit, @user
    update_params = params
    if params.has_key?("user")
      update_params=params["user"]
    end

    respond_to do |format|

	auth_service = current_user.auth_services.find_by_provider('roxiware')
	if auth_service.present?
	    # attempt to update the password on the auth server

	    uri = URI(URI.join(@auth_server, account_update_password_path).to_s+".json?"+params.slice(:user).to_param)

	    http = Net::HTTP.new(uri.host, uri.port)
	    if uri.scheme == 'https'
		http.use_ssl = true
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	    end
	    req = Net::HTTP::Put.new(uri.to_s, initheader = { 'Content-Type' => 'text/plain'})
	    req.basic_auth current_user.username, params[:user][:current_password]
	    req.body = ""
	    password_update_response = http.request(req)
	    result_data = {}
	    result_data = JSON.parse(password_update_response.body) if password_update_response.code.to_i == 200
            
	    if password_update_response.present? && password_update_response.code.to_i == 200
		format.json { render :json=>result_data}
		if result_data['error'].present?
		    format.html { redirect_to "/",  :alert=>"Failed to update password." }
                else
		    flash[:notice] = "Password successfully updated."
		    format.html { redirect_to "/",  :alert=>"Password successfully updated.." }
                end
            elsif password_update_response.present? && password_update_response.code.to_i == 401
		format.json { render :json=>{:error=>[["current_password", "Current password is invalid."]] }}
		format.html { redirect_to "/",  :alert=>"Current password is invalid" }
            else
		format.json { render :nothing=>true, :status=>password_update_response.code}
		format.html { redirect_to "/",  :alert=>"Failure updating password." }
            end

        else
            # no remote server for this user, so update it locally
	    if(update_params[:password].blank?) 
		format.json { render :json=>{:error=>[["password", "New password can't be blank."]] }}
		format.html { redirect_to "/",  :alert=>"Password cannot be blank." }
	    elsif @user.valid_password?(update_params[:current_password]) 
		if !@user.update_attributes(update_params, :as=>current_user.role)
		   format.json { render :json=>report_error(@user)}
		   format.html { redirect_to "/", :alert=>flash_from_object_errors(@user) } 
		else
		  format.json { render :json=>@user.ajax_attrs(@role)}
		  format.html { redirect_to "/",  :notice=>"Password successfully updated.  You will need to log in again." }
		end
	    else
		format.json { render :json=>{:error=>[["current_password", "Current password is invalid."]] }}
		format.html { redirect_to "/",  :alert=>"Current password is invalid" }
	    end
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
