
class Roxiware::EventsController < ApplicationController
  include Roxiware::EventsHelper
  load_and_authorize_resource :except=>[:index, :new], :class=>"Roxiware::Events"
  
  before_filter do
    @role = "guest"
    @role = current_user.role unless current_user.nil?
  end

  def index
    logger.debug(params.to_json)
    @events = Roxiware::Event.where("start >= :start_date", :start_date=>Time.now.utc.midnight).order("start ASC")
    @title = @title + " : Events"
    @meta_description = @meta_description +" : Events"
    authorize! :read, Roxiware::Event
  end

  def show
    @robots="noindex,nofollow"
    @title = @title + " : Events : " +  @event.start.to_s
    @meta_description = @meta_description +" : Events"
    @meta_keywords = @meta_keywords + ", " + @event.start.to_s
    respond_to do |format|
      format.html { render }
      format.json { render :json => @event.ajax_attrs(@role) }
    end
  end


  def edit
    @robots="noindex,nofollow"
    @title = @title + " : Events : " +  @event.start.to_s
    @meta_description = @meta_description +" : Events"
    @meta_keywords = @meta_keywords + ", " + @event.start.to_s
    respond_to do |format|
      format.html { render }
      format.json { render :json => @event.ajax_attrs(@role) }
    end
  end

  def new
    @robots="noindex,nofollow"
    authorize! :create, Roxiware::Event
    @event = Roxiware::Event.new({:start_date=>Time.now.utc.strftime("%F"), :start_time=>"8:00 AM", :description=>"Description", :location=>"", :location_url=>""}, :as=>@role)
    respond_to do |format|
      format.html
      format.json { render :json => @event.ajax_attrs(@role) }
    end
  end

  
  def create
     @robots="noindex,nofollow"
     respond_to do |format|
       if !@event.update_attributes(params, :as=>@role)
         format.json { render :json=>report_error(@event) }
       else
         format.json { render :json=> @event.ajax_attrs(@role) }
       end
     end
  end

  def update
     @robots="noindex,nofollow"
     respond_to do |format|
       if !@event.update_attributes(params, :as=>@role)
         format.json { render :json=>report_error(@event)}
       else
         format.json { render :json=> @event.ajax_attrs(@role) }
       end
     end
  end

  def destroy
    @robots="noindex,nofollow"
    respond_to do |format|
      if !@event.delete
        format.json { render :json=>report_error(@event)}
      else
        format.json { render :json=>{}}
      end
    end
  end
end
