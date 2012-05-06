class Roxiware::ServicesController < ApplicationController
  load_and_authorize_resource :except => [ :index, :show_seo ]


  # GET /services
  # GET /services.json
  def index
    @portfolio_entries = Roxiware::PortfolioEntry.where(:service_class =>params[:class]).order("RANDOM()").limit(5).map
    @title = @title + " : " + params[:class].capitalize
    @meta_description = @title
    @header = Roxiware::Page.where(:page_type => 'service_'+params[:class]).first
    if @header.nil?
       @header = Roxiware::Page.new({:page_type => 'service_'+params[:class]})
    end
    @services = Roxiware::Service.where(:service_class => params[:class]).order("id ASC")
    (render :status => :unauthorized; return) unless can? :read, @services

    @services.each do |service|
       @meta_keywords = @meta_keywords + ", " + service.name
    end
    respond_to do |format|
        format.html
        format.json { render :json => @services }
    end
  end

  def show
    @services = Roxiware::Service.where(:service_class => params[:class]).order("id ASC")
    @title = @title + " : " + @service.service_class.capitalize + " : " + @service.name
    @meta_description = @title
    @meta_keywords = @meta_keywords + ", " + @service.name
    @service["can_edit"] = @service.writeable_attribute_names(current_user)
    respond_to do |format|
      format.html { redirect_to :action=>"show_seo", :class=>@service.service_class, :seo_index => @service.seo_index }
      format.json { render :json => @service }
    end
  end

  def show_seo
    @services = Roxiware::Service.where(:service_class => params[:class]).order("id ASC")
    @service = Roxiware::Service.where(:seo_index=>params[:seo_index], :service_class=>params[:class]).first
    @title = @title + " : " + params[:class].capitalize + " : " + @service.name
    @meta_description = @title
    @meta_keywords = @meta_keywords + ", " + @service.name
    (render status => :not_found; return) if @service.nil?
    (render status => :unauthorized; return) unless(can? :read, @service)
    @service["can_edit"] = @service.writeable_attribute_names(current_user)
    respond_to do |format|
       format.html { render :action => 'show' }
       format.json { render :json => @service }
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
       
       if @service.update_attributes(params, :as=>current_user.role)
           logger.debug("success updating")
	   format.html { redirect_to @service, :notice => 'Service was successfully updated.' }
           format.json { render :json => @service }
       else
           logger.debug("failure updating")
	   format.html { redirect_to @service, :notice => 'Failure updating service.' }
           format.json { render :json => report_error(@service) }
       end
    end
  end

  def new
    # must use hash as we don't want to send up the service_class attribute.  That's set by the initial rendering of the page
    @service = {:name=>"Name", :summary=>"Summary", :description=>"Description", :can_edit=>[:name, :summary, :description]}
   
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @service }
    end
  end

  def create
    respond_to do |format|
      if @service.update_attributes(params, :as=>current_user.role)
         format.html { redirect_to @service, :notice => 'Service was successfully created.' }
         format.json { render :json => @service }
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
