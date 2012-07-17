class Roxiware::ServicesController < ApplicationController
  load_and_authorize_resource :except => [ :index, :show_seo, :new ], :class=>"Roxiware::Service"

  before_filter do
    @role = "guest"
    @role = current_user.role unless current_user.nil?
  end


  # GET /services
  # GET /services.json
  def index
    authorize! :read, Roxiware::PortfolioEntry
    @portfolio_entries = Roxiware::PortfolioEntry.where(:service_class =>params[:service_class]).order("RANDOM()").limit(5).map
    @title = @title + " : " + params[:service_class].capitalize
    @meta_description = @title
    @header = Roxiware::Page.where(:page_type => 'service_'+params[:service_class]).first || Roxiware::Page.new({:page_type => 'service_'+params[:service_class]}, :as=>"")
    authorize! :read, @header
    @services = Roxiware::Service.where(:service_class => params[:service_class]).order("id ASC")
    raise ActiveRecord::RecordNotFound if @services.nil?
    authorize! :read, Roxiware::Service

    @services.each do |service|
       if can? :read, service
         @meta_keywords = @meta_keywords + ", " + service.name
       end
    end
    respond_to do |format|
        format.html
    end
  end

  def show
    @services = Roxiware::Service.where(:service_class => params[:service_class]).order("id ASC")
    authorize! :read, Roxiware::Service
    @title = @title + " : " + @service.service_class.capitalize + " : " + @service.name
    @meta_description = @title
    @meta_keywords = @meta_keywords + ", " + @service.name
    respond_to do |format|
      format.html { redirect_to :action=>"show_seo", :service_class=>@service.service_class, :seo_index => @service.seo_index }
      format.json { render :json => @service.ajax_attrs(@role) }
    end
  end

  def show_seo
    @services = Roxiware::Service.where(:service_class => params[:service_class]).order("id ASC")
    authorize! :read, Roxiware::Service
    @service = Roxiware::Service.where(:seo_index=>params[:seo_index], :service_class=>params[:service_class]).first
    raise ActiveRecord::RecordNotFound if @service.nil?
    authorize! :read, @service
    @title = @title + " : " + params[:service_class].capitalize + " : " + @service.name
    @meta_description = @title
    @meta_keywords = @meta_keywords + ", " + @service.name
    respond_to do |format|
       format.html { render :action => 'show' }
       format.json { render :json => @service.ajax_attrs(@role) }
    end
  end
 
  def _move_service(service, direction)
     if direction == "up"
        other_service = Roxiware::Service.where("service_class = ? and id < ?", @service.service_class, params[:id]).order("id DESC").limit(1).first
     elsif direction == "down"
        other_service = Roxiware::Service.where("service_class = ? and id > ?", @service.service_class, params[:id]).order("id ASC").limit(1).first
     else
 	other_service = nil
     end
     if other_service
        swap_objects(service, other_service)
     else
        service
     end
  end


  def update
     respond_to do |format|
       if params.has_key?(:move)
          @service = _move_service(@service, params[:move])
       end
       
       if @service.update_attributes(params, :as=>@role)
           logger.debug("success updating")
	   format.html { redirect_to @service, :notice => 'Service was successfully updated.' }
           format.json { render :json => @service.ajax_attrs(@role) }
       else
           logger.debug("failure updating")
	   format.html { redirect_to @service, :notice => 'Failure updating service.' }
           format.json { render :json => report_error(@service) }
       end
    end
  end

  def new
    authorize! :create, Roxiware::Service
    # must use hash as we don't want to send up the service_class attribute.  That's set by the initial rendering of the page
    @service = Roxiware::Service.new({:name=>"Name", :summary=>"Summary", :description=>"Description"}, :as=>current_user.role)
   
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @service.ajax_attrs(@role) }
    end
  end

  def create
    respond_to do |format|
      @service.service_class=params[:service_class]
      if @service.update_attributes(params, :as=>@role)
         format.html { redirect_to @service, :notice => 'Service was successfully created.' }
         format.json { render :json => @service.ajax_attrs(@role) }
      else
	 format.html { redirect_to @service, :notice => "Couldn't create service." }
	 format.json { render :json=>report_error(@service)}
      end
    end
  end


  def destroy
    respond_to do |format|
       if !@service.delete
         format.json { render :json=>report_error(@user)}
       else
         format.json { render :json=>{}}
         format.html { redirect_to services_url }
       end
    end
  end
end
