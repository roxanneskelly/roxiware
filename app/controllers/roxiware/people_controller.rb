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
        @page_title = @title + " : People"
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
            @page_title = @person.full_name
            respond_to do |format|
                format.html { render :action=>"show" }
            end
        end
    end

    def show
        people = Roxiware::Person.all
        # iterate each person to see if user can read them
        @people = people.select { |person| can? :read, person }
        @page_title = @person.full_name
        @page_images = [@person.large_image, @person.image, @person.thumbnail]
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
        _create_or_update(@person)
    end

    # PUT /people/:id
    # PUT /people/:id.json
    def update
        @person = Roxiware::Person.find(params[:id])
        _create_or_update(@person)
    end

    def _create_or_update(person)
        success = true
        result = {}
        ActiveRecord::Base.transaction do
            begin
                social_networks = person.set_param("social_networks", {}, "4EB6BB84-276A-4074-8FEA-E49FABC22D83", "local")
                params[:person][:social_networks].each do |name, value|
                    social_network = social_networks.set_param(name, {}, "5CC121A6-AB23-49B4-BB14-0E03119F00E6", "local")
                    social_network.set_param("uid", value, "FB528C00-8510-4876-BD82-EF694FEAC06D", "local")
                end
                @person.assign_attributes(params[:person], :as=>@role)
                @person.save
                if(@person.errors.present?)
                    result = report_error(@person)
                else
                    result = @person.ajax_attrs(@role);
                end
            rescue Exception => e
                result = { :error=>["exception", e.message] }
                logger.error e.message
                logger.error e.backtrace.join("\n")
            end
            raise ActiveRecord::Rollback if result[:error].present?
        end
        run_layout_setup if result[:error].blank?
        respond_to do |format|
            if result[:error].blank?
                format.html { redirect_to "/biography/#{@person.seo_index}", :notice => 'Person was successfully updated.' }
                format.json { render :json => result }
            else
                format.html { redirect_to "/biography/#{@person.seo_index}", :notice => 'Failure updating person.' }
                format.json { render :json=>result}
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
