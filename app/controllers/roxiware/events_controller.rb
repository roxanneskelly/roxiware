
class Roxiware::EventsController < ApplicationController
  application_name "events"
  include Roxiware::EventsHelper
  load_and_authorize_resource :except=>[:index, :new], :class=>"Roxiware::Event"
  
  before_filter do
    @role = "guest"
    @role = current_user.role unless current_user.nil?
  end

  def index
    time_check = Time.now.utc.midnight 
    time_check -= 1.month if current_user.present? && current_user.is_admin?
    @events = (Roxiware::Event.order("start ASC").select{|event| event.end_time > time_check}) || []
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
      format.html { render :partial =>"roxiware/events/editform" }
      format.json { render :json => @event.ajax_attrs(@role) }
    end
  end

  def new
    @robots="noindex,nofollow"
    authorize! :create, Roxiware::Event
    @event = Roxiware::Event.new({:start_date=>Time.now.utc.strftime("%F"), :start_time=>"8:00 AM", :description=>"", :location=>"", :location_url=>"", :duration_units=>"hours", :duration=>"1"}, :as=>@role)
    respond_to do |format|
      format.html { render :partial =>"roxiware/events/editform" }
      format.json { render :json => @event.ajax_attrs(@role) }
    end
  end

  
  def create
     @robots="noindex,nofollow"
     if (params[:event][:duration].blank?)
         params[:event][:duration_units] = "none"
     end
     respond_to do |format|
       @event.assign_attributes(params[:event], :as=>@role)
       if @event.save
         format.json { render :json=> @event.ajax_attrs(@role) }
       else
         format.json { render :json=>report_error(@event) }
       end
     end
  end

  def update
     @robots="noindex,nofollow"
     if (params[:event][:duration].blank?)
         params[:event][:duration_units] = "none"
     end
     respond_to do |format|
       @event.assign_attributes(params[:event], :as=>@role)
       if !@event.save
         format.json { render :json=>report_error(@event)}
       else
         format.json { render :json=> @event.ajax_attrs(@role) }
       end
     end
  end

  def destroy
    @robots="noindex,nofollow"
    respond_to do |format|
      if !@event.destroy
        format.json { render :json=>report_error(@event)}
      else
        format.json { render :json=>{}}
      end
    end
  end
end
