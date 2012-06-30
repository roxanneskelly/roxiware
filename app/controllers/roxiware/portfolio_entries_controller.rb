class Roxiware::PortfolioEntriesController < ApplicationController
  load_and_authorize_resource :except => [:new]

  before_filter do
    @role = "guest"
    @role = current_user.role unless current_user.nil?
  end

  # GET /portfolio_entries
  # GET /portfolio_entries.json
  def index
    @title = @title + " : Portfolio"
    @meta_description = @title
    @portfolio_entries.each do |portfolio_entry| 
      @meta_keywords = @meta_keywords + ", " + portfolio_entry.name
    end 
  end

  # GET /portfolio_entries/:id
  # GET /portfolio_entries/:id.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @portfolio_entry.ajax_attrs(@role) }
    end
  end

  # GET /portfolio_entries/new
  # GET /portfolio_entries/new.json
  def new
    authorize! :create, Roxiware::PortfolioEntry
    @portfolio_entry = Roxiware::PortfolioEntry.new({:name=>"Name", :service_class=>"web", :description=>"Description", :url=>"", :blurb=>"blurb"}, :as=>current_user.role)
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @portfolio_entry.ajax_attrs(@role) }
    end
  end

  # POST /portfolio_entries
  # POST /portfolio_entries.json
  def create
      uri_obj = URI
      respond_to do |format|
        if @portfolio_entry.update_attributes(params, :as=>@role)
	   format.html { redirect_to @portfolio_entry, :notice => 'Portfolio Entry was successfully updated.' }
           format.json { render :json => @portfolio_entry.ajax_attrs(@role) }
        else
	   format.html { redirect_to @portfolio_entry, :notice => 'Failure updating Portfolio Entry.' }
           format.json { render :json=>report_error(@portfolio_entry)}
	end
      end
  end

  # PUT /portfolio_entries/1
  # PUT /portfolio_entries/1.json
  def update
      respond_to do |format|
        if @portfolio_entry.update_attributes(params, :as=>@role)
           format.html { redirect_to @portfolio_entry, :notice => 'Portfolio entry was successfully updated.' }
           format.json { render :json => @portfolio_entry.ajax_attrs(@role) }
        else
	   format.html { redirect_to @portfolio_entry, :notice => 'Failure updating Portfolio entry.' }
           format.json { render :json=>report_error(@portfolio_entry)}
        end
      end
  end

  # DELETE /portfolio_entries/1
  # DELETE /portfolio_entries/1.json
  def destroy
    respond_to do |format|
      if !@portfolio_entry.destroy
        format.json { render :json=>report_error(@portfolio_entry)}
      else
        format.json { render :json=>{}}
      end
    end
  end
end
