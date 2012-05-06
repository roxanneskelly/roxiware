class Roxiware::PortfolioEntriesController < ApplicationController
  load_and_authorize_resource :except => [ :show_seo ]

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
    @portfolio_entry["can_edit"] = @portfolio_entry.writeable_attribute_names(current_user)
    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @portfolio_entry }
    end
  end

  def show_seo
  end

  # GET /portfolio_entries/new
  # GET /portfolio_entries/new.json
  def new
    @portfolio_entry["name"] = "Name"
    @portfolio_entry["service_class"] = "web"
    @portfolio_entry["description"] = "description"
    @portfolio_entry["url"] = "url"
    @portfolio_entry["blurb"] = "blurb"
    @portfolio_entry["can_edit"] = @portfolio_entry.writeable_attribute_names(current_user)
    
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @portfolio_entry.to_json }
    end
  end

  # POST /portfolio_entries
  # POST /portfolio_entries.json
  def create
      respond_to do |format|
        if @portfolio_entry.update_attributes(params, :as=>current_user.role)
	   format.html { redirect_to @portfolio_entry, :notice => 'Portfolio Entry was successfully updated.' }
           format.json { render :json => @portfolio_entry }
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
        if @portfolio_entry.update_attributes(params, :as=>current_user.role)
           format.html { redirect_to @portfolio_entry, :notice => 'Portfolio entry was successfully updated.' }
           format.json { render :json => @portfolio_entry }
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
