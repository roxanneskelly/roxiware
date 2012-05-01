class Roxiware::AccountController < ApplicationController
  load_and_authorize_resource :except => [ :show, :edit ], :class=>"Roxiware::User"

  # GET - enumerate user
  def index
    @robots="noindex,nofollow"
    logger.debug(@users)
    @users = Roxiware::User.all()
  end

  # GET - show a user
  def show
    @robots="noindex,nofollow"
    if (params[:id] == "0")
      @user = Roxiware::User.find(current_user.id)
    else 
      @user = Roxiware::User.find(params[:id])
    end

    render :status => :not_found unless(!@user.nil?)
    render :status => :unauthorized unless can? :read, @user
    respond_to do |format|
      @user["can_edit"] = @user.writable_attribute_names(current_user)
      @user.password=""
      @user.password_confirmation=""
      format.html { render }
      format.json { render :json => @user }
    end
  end

  # GET - return form for editing user
  def edit
    @robots="noindex,nofollow"
    if (params[:id] == 0)
      @user = Roxiware::User.find(current_user.id)
    else 
      @user = Roxiware::User.find(params[:id])
    end
    render :status => :not_found unless(!@user.nil?)
    render :status => :unauthorized unless can? :read, @user
    respond_to do |format|
      @user["can_edit"] = @user.writable_attribute_names(current_user)
      @user.password=nil
      @user.password_confirmation=nil
      format.html { render }
      format.json { render :json => @user }
    end
  end

  # GET - return form for new user creation
  def new
    @robots="noindex,nofollow"
    @user = Roxiware::User.new({:email => "email.com", :username=>"username", :name=>"name"}, :as=>current_user.role )
    @user["can_edit"] = @user.writable_attribute_names(current_user)
    respond_to do |format|
        format.html
        format.json { render :json => @user }
    end
  end

  # POST - create a user
  def create
    @robots="noindex,nofollow"
    respond_to do |format|
      @user = Roxiware::User.new
	
      if !@user.update_without_password(params, :as=>current_user.role)
         format.json { render :json=>report_error(@user)}
      else
         format.json { render :json => @user }
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
    render status => :not_found if @user.nil?
    render status => :unauthorized unless(can? :edit, @user)

    respond_to do |format|
      update_params = params
      if params.has_key?("user")
        update_params=params["user"]
      end
      if update_params.has_key?("password") && update_params["password"].empty?()
         update_params.delete("password")
         update_params.delete("password_confirmation")
      end
      if !@user.update_without_password(params, :as=>current_user.role)
         format.json { render :json=>report_error(@user)}
      else
        format.json { render :json => @user }
        format.html { redirect_to "/", :notice=>"User successfully updated"}
      end
    end
  end

  # DELETE - delete a user
  def destroy
    @robots="noindex,nofollow"
    @user = Roxiware::User.find(params[:id])
    respond_to do |format|
      if @user == current_user 
        format.json { render :json=>{:error=>[nil, "You cannot delete yourself"]}}
      end
      if !@user.delete
        format.json { render :json=>report_error(@user)}
      else
        format.json { render :json=>{}}
      end
    end
  end
end
