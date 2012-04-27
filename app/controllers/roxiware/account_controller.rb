class Roxiware::AccountController < ApplicationController
  respond_to :html
  
  ADMIN_EDIT_VALUES = ["username", "email", "name", "role", "password", "password_confirmation"]
  
  def allowed_edit_values(operation, object)
     if can? operation, object
        if params[:id]=="0"
           ["email", "name", "password", "password_confirmation"]
        else
           result = ["username", "email", "name", "password", "password_confirmation"]
	   result << "role" unless (object == current_user)
	   result
        end
     else
       nil
     end
  end

  def report_error(object)
    error_out = []
    object.errors.each do |attribute, error|
      error_out << [attribute.to_s(), error.to_s()]
    end
    return {:error=>error_out}
  end

  # GET - enumerate user
  def index
    render :status => :unauthorized unless can? :read, Roxiware::User
    @robots="noindex,nofollow"
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
      @user["can_edit"] = allowed_edit_values(:edit, @user)
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
      @user["can_edit"] = allowed_edit_values(:edit, @user)
      @user.password=nil
      @user.password_confirmation=nil
      format.html { render }
      format.json { render :json => @user }
    end
  end

  # GET - return form for new user creation
  def new
    render :status => :unauthorized unless can? :create, Roxiware::User
    @robots="noindex,nofollow"
    @user = Roxiware::User.new()
    @user.email ="email@email.com"
    @user.username ="username"
    @user.name = "name"
    @user["can_edit"] = allowed_edit_values(:create, Roxiware::User)
    respond_to do |format|
        format.html
        format.json { render :json => @user }
    end
  end

  # POST - create a user
  def create
    render :status => :unauthorized unless can? :create, Roxiware::User
    @robots="noindex,nofollow"
    respond_to do |format|
      logger.debug("creating user")
      @user = Roxiware::User.new()
	
      update_params = {}
      allowed_edit_values(:create, Roxiware::User).each do |attribute_name|
        if params.has_key?(attribute_name)
          update_params[attribute_name] = params[attribute_name]
        end
      end
      if !@user.update_without_password(update_params)
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
      @user = Roxiware::User.find(params[:id])
    end
    render status => :not_found unless(!@user.nil?)
    render status => :unauthorized unless(can? :edit, @user)

    respond_to do |format|
      update_params = {}
      if params.has_key?("user")
        check_params=params["user"]
      else
        check_params=params
      end
      allowed_edit_values(:edit, @user).each.each do |attribute_name|
        if check_params.has_key?(attribute_name)
          update_params[attribute_name] = check_params[attribute_name]
        end
      end
      if update_params.has_key?("password") && update_params["password"].empty?()
         update_params.delete("password")
         update_params.delete("password_confirmation")
      end

      if !@user.update_without_password(update_params)
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
    render status => :not_found unless(!@user.nil?)
    render status => :unauthorized unless(can? :destroy, @user)
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
