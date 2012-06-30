class Roxiware::PeopleController < ApplicationController
  require 'uri'
  load_and_authorize_resource :except => [ :show_seo, :new ]

  before_filter do
    @role = "guest"
    @role = current_user.role unless current_user.nil?
  end

  # GET /people
  def index
    @title = @title + " : People"
    @meta_description = @meta_description +" : People"
    @people ||= []
    @people.each do |person|
      @meta_keywords = @meta_keywords + ", " + person.first_name
      if !person.last_name.blank?
        @meta_keywords = @meta_keywords  + " " + person.last_name
      end
    end
    @person = @people.first
    if (@person.nil? || @person.seo_index.nil?)
        respond_to do |format|
            format.html 
        end
    else
        respond_to do |format|
	    if Roxiware.single_person
                 format.html { render :action=>"show" }
	    else
              format.html { redirect_to :action=>'show_seo', :seo_index => @person.seo_index }

            end
        end
    end
  end


  def show
    people = Roxiware::Person.all
    # iterate each person to see if user can read them
    @people = people.select { |person| can? :read, person }
    print "Person user id is " + @person.user_id.to_s + "\n\n"
    @title = @title + ": People : " + @person.first_name + " " + @person.last_name
    respond_to do |format|
       format.html # show.html.erb
       format.json { render :json => @person.ajax_attrs(@role) }
    end
  end

  def edit
    @people = Roxiware::Person.all
    @title = @title + ": People : " + @person.first_name + " " + @person.last_name
    respond_to do |format|
       format.html # show.html.erb
       format.json { render :json => @person.ajax_attrs(@role) }
    end
  end

  # GET /people/seo-name
  # GET /people/seo-name.json
  def show_seo
    people = Roxiware::Person.all
    @people = people.select { |person| can? :read, person }
    if params[:seo_index].blank?
      people.each do |person|
         print person.to_json
      end
      @person = people.select { |person| person.show_in_directory }.first
    else
      @person = Roxiware::Person.where(:seo_index => params[:seo_index]).first
    end
    raise ActiveRecord::RecordNotFound if @person.nil?
    authorize! :read, @person
    @title = @title + ": People : " + @person.first_name + " " + @person.last_name
    @meta_description = @title
    @meta_keywords = @meta_keywords + ", " + @person.first_name + " " + @person.last_name
    respond_to do |format|
      format.html { render :action => 'show' }
      format.json { render :json => @person.ajax_attrs(@role) }
    end
  end

  # GET /people/new
  # GET /people/new.json
  def new
   @robots="noindex,nofollow"
   authorize! :create, Roxiware::Person
   @person = Roxiware::Person.new({:show_in_directory=>true,
                                   :first_name=>"First", 
                                   :last_name=>"Last", 
				   :role=>"Role", 
				   :email=>"email@email.com", 
				   :bio=>"Bio"}, :as=>@role)
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @person.ajax_attrs(@role) }
    end
  end

  
  # POST /people
  # POST /people.json
  def create
    respond_to do |format|
      if @person.update_attributes(params, :as=>@role)
        format.html { redirect_to @person, :notice => 'Person was successfully created.' }
        format.json { render :json => @person, :status => :created, :location => @person }
      else
        format.html { redirect_to @persone, :notice => "Couldn't create person." }
        format.json { render :json => report_error(@person) }
      end
    end
  end

  # PUT /people/:id
  # PUT /people/:id.json
  def update
    respond_to do |format|
        if @person.update_attributes(params, :as=>@role)
	   format.html { redirect_to @person, :notice => 'Person was successfully updated.' }
           format.json { render :json => @person }
	else
	   format.html { redirect_to @person, :notice => 'Failure updating person.' }
	   format.json { head :fail }
	end
    end
  end

  # DELETE /people/1
  # DELETE /people/1.json
  def destroy
    @person = Roxiware::Person.find(params[:id])
    print "destroying person with user id of " + @person.user_id.to_s + "\n\n"
    respond_to do |format|
        if !@person.user_id.nil?
          format.json { render :json=>{:error=>[nil, "This person is associated with a user.  Delete the user instead."]}}
	else
           if @person.destroy
	      format.html { redirect_to people_url }
              format.json { head :ok }
	   else
	      format.json { render :json=>report_error(@person)}
	   end
	end
    end
  end
end
