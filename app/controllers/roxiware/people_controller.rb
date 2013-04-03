class Roxiware::PeopleController < ApplicationController
  require 'uri'

  application_name "people"

  load_and_authorize_resource :except => [ :index, :show_seo, :new ], :class=>"Roxiware::Person"

  before_filter do
    redirect_to("/") unless @enable_people
    @role = "guest"
    @role = current_user.role unless current_user.nil?
  end

  # GET /people
  def index
    @title = @title + " : People"
    people = Roxiware::Person.all
    @person = Roxiware::Person.where(:id=>@default_biography).first if @default_biography.present?
    @person = nil if cannot? :read, @person
    # iterate each person to see if user can read them
    @people = people.select { |person| can? :read, person }
    @people.each do |person|
      @meta_keywords = @meta_keywords + ", " + person.full_name
    end
    @person ||= @people.first 
    if (@person.nil? || @person.seo_index.nil?)
        respond_to do |format|
            format.html 
        end
    else
        @title = @title + " : " + @person.full_name
        respond_to do |format|
            format.html { render :action=>"show" }
        end
    end
  end

  def show
    people = Roxiware::Person.all
    # iterate each person to see if user can read them
    @people = people.select { |person| can? :read, person }
    @title = @title + ": People : " + @person.full_name

    respond_to do |format|
       format.html # show.html.erb
       format.json { render :json => @person.ajax_attrs(@role) }
    end
  end

  def edit
    respond_to do |format|
      format.html { render :partial =>"roxiware/people/editform" }
    end
  end

  # GET /people/seo-name
  # GET /people/seo-name.json
  def show_seo
    people = Roxiware::Person.all
    @people = people.select { |person| can? :read, person }
    if params[:seo_index].blank?
      @person = people.select { |person| person.show_in_directory }.first
    else
      @person = Roxiware::Person.where(:seo_index => params[:seo_index]).first
    end
    raise ActiveRecord::RecordNotFound if @person.nil?
    authorize! :read, @person
    @title = @title + ": People : " + @person.full_name
    @meta_keywords = @meta_keywords + ", " + @person.full_name

    @recent_posts = Roxiware::Blog::Post.published().where(:person_id=>@person.id).order("post_date DESC").limit(5).collect{|post| post}

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
                                   :middle_name=>"", 
                                   :last_name=>"Last", 
				   :role=>"Role", 
				   :email=>"email@email.com", 
				   :bio=>"Bio"}, :as=>@role)
    respond_to do |format|
      format.html { render :partial =>"roxiware/people/editform" }
      format.json { render :json => @person.ajax_attrs(@role) }
    end
  end

  
  # POST /people
  # POST /people.json
  def create
    respond_to do |format|
      if @person.update_attributes(params[:person], :as=>@role)
        run_layout_setup
        format.html { redirect_to "/biography/#{@person.seo_index}", :notice => 'Person was successfully created.' }
        format.json { render :json => @person, :status => :created, :location => @person }
      else
        format.html { redirect_to "/biography/#{@person.seo_index}", :notice => "Couldn't create person." }
        format.json { render :json => report_error(@person) }
      end
    end
  end

  # PUT /people/:id
  # PUT /people/:id.json
  def update
    respond_to do |format|
        if @person.update_attributes(params[:person], :as=>@role)
           run_layout_setup
	   format.html { redirect_to "/biography/#{@person.seo_index}", :notice => 'Person was successfully updated.' }
           format.json { render :json => @person }
	else
	   format.html { redirect_to "/biography/#{@person.seo_index}", :notice => 'Failure updating person.' }
	   format.json { head :fail }
	end
    end
  end

  # DELETE /people/1
  # DELETE /people/1.json
  def destroy
    @person = Roxiware::Person.find(params[:id])
    respond_to do |format|
        if !@person.user_id.nil?
          run_layout_setup
          format.json { render :json=>{:error=>[nil, "This person is associated with a user.  Delete the user instead."]}}
	else
           if @person.destroy
              format.json { render :json=>{:success=>true} }
	   else
	      format.json { render :json=>report_error(@person)}
	   end
	end
    end
  end
end
