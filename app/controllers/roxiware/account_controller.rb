class Roxiware::AccountController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource :except=>[:edit, :update, :show, :new], :class=>"Roxiware::User"

  before_filter do
    @role = current_user.role 
    @role = "self" if current_user == @user
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
         format.json { render :json => @user.ajax_attrs(@role) }
         if update_params.has_key?("password")
             format.html { redirect_to "/", :notice=>"User successfully updated.  You must log in again."}
	 else
	     format.html { redirect_to "/",  :notice=>"User successfully updated" }
	 end
      end
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
        if(update_params[:password].blank?) 
	    format.html { redirect_to "/",  :alert=>"Password cannot be blank." }
	elsif @user.valid_password?(update_params[:current_password]) 
	    if !@user.update_attributes(update_params, :as=>current_user.role)
	       format.html { redirect_to "/", :alert=>flash_from_object_errors(@user) } 
	    else
	      format.html { redirect_to "/",  :notice=>"Password successfully updated.  You will need to log in again." }
	    end
	else
	    format.html { redirect_to "/",  :alert=>"Current password is invalid" }
	end

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
      @user.person.user_id=nil
      @user.person.save
      if !@user.destroy
        format.json { render :json=>report_error(@user)}
      else
        format.json { render :json=>{}}
      end
    end
  end
end
