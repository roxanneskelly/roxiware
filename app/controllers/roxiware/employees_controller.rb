class Roxiware::EmployeesController < ApplicationController
  require 'uri'
  load_and_authorize_resource :except => [ :show_seo ]

  # GET /employees
  # GET /employees.json
  def index
    @employees = Roxiware::Employee.all
    @title = @title + " : People"
    @meta_description = @meta_description +" : People"
    @employees.each do |employee|
      @meta_keywords = @meta_keywords + ", " + employee.first_name + " " + employee.last_name
    end
    first_employee = @employees.first
    if (first_employee.nil? || first_employee.seo_index.nil?)
        respond_to do |format|
            format.html 
            format.json
        end
    else
        respond_to do |format|
            format.html { redirect_to :action=>'show_seo', :seo_index =>
first_employee.seo_index }
            format.json { render :json => @employees }
        end
    end
  end


  def show
    @employees = Roxiware::Employee.all
    @title = @title + ": People : " + @employee.first_name + " " + @employee.last_name
    respond_to do |format|
      if @employee.nil?
         format.html { redirect_to @employee, :notice => 'Employee did not exist.' }
         format.json { head :not_found }
      else
         @employee["can_edit"] = @employee.writeable_attribute_names(current_user)
         @social_networks = SocialNetwork.where(:employee_id=>params[:id])
         @social_networks.each do |network|
            @employee[network.network_type] = network.network_link
         end
         format.html # show.html.erb
         format.json { render :json => @employee }
      end
    end
  end

  # GET /people/seo-name
  # GET /people/seo-name.json
  def show_seo
    @employees = Roxiware::Employee.all
    @employee = Roxiware::Employee.where(:seo_index => params[:seo_index]).first
    @title = @title + ": People : " + @employee.first_name + " " + @employee.last_name
    @meta_description = @title
    @meta_keywords = @meta_keywords + ", " + @employee.first_name + " " + @employee.last_name
    @employee["can_edit"] = @employee.writeable_attribute_names(current_user)
    @social_networks = SocialNetwork.where(:employee_id=>@employee.id)

    respond_to do |format|
      format.html { render :action => 'show' }
      format.json { render :json => @employee }
    end
  end

  # GET /employees/new
  # GET /employees/new.json
  def new
    @employee["first_name"] = "First"
    @employee["last_name"] = "Last"
    @employee["role"] = "Role"
    @employee["email"] = "email@email.com"
    @employee["bio"] = "Bio"
    @employee["can_edit"] = @employee.writeable_attribute_names(current_user)
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @employee.to_json }
    end
  end

  
  # POST /employees
  # POST /employees.json
  def create
    respond_to do |format|
      if @employee.update_attributes(params, :as=>current_user.role)
       ["website", "twitter", "facebook", "google"].each do |network_type|
	   if(params[network_type]) && (params[network_type] != "")
               Roxiware::SocialNetwork.create({:employee_id=>@employee.id, :network_type=> network_type, :network_link => params[network_type]})
           end
        end
        format.html { redirect_to @employee, :notice => 'Employee was successfully created.' }
        format.json { render :json => @employee, :status => :created, :location => @employee }
      else
        format.html { redirect_to @employeee, :notice => "Couldn't create employee." }
        format.json { render :json => report_error(@employee) }
      end
    end
  end

  # PUT /employees/:id
  # PUT /employees/:id.json
  def update
    respond_to do |format|
        if @employee.update_attributes(params, :as=>current_user.role)
	    Roxiware::SocialNetwork.delete_all(:employee_id=>params[:id])
	    ["website", "twitter", "facebook", "google"].each do |network_type|
	        if(params[network_type]) && (params[network_type] != "")
                   SocialNetwork.create({:employee_id=>params[:id], :network_type=> network_type, :network_link => params[network_type]})
                end
            end
	   format.html { redirect_to @employee, :notice => 'Employee was successfully updated.' }
           format.json { render :json => @employee }
	else
	   format.html { redirect_to @employee, :notice => 'Failure updating employee.' }
	   format.json { head :fail }
	end
    end
  end

  # DELETE /employees/1
  # DELETE /employees/1.json
  def destroy
    @employee = Roxiware::Employee.find(params[:id])
    @employee.destroy
    respond_to do |format|
        format.html { redirect_to employees_url }
        format.json { head :ok }
    end
  end
end
