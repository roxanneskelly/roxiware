module Roxiware
  class NewsItemController < ApplicationController
    load_and_authorize_resource  :except=>[:new, :index]

  before_filter do
    @role = "guest"
    @role = current_user.role unless current_user.nil?
  end

    # GET /news_items
    # GET /news_items.json
    def index
      @enable_news_edit = true
      @news = Roxiware::NewsItem.order("post_date DESC")
      @title = @title + " : News"
      @meta_description = @title
      clean_news = []
      @news.each do |news_item| 
        @meta_keywords = @meta_keywords + ", " + news_item.headline
	clean_news << news_item.ajax_attrs(@role)
      end 
      respond_to do |format|
        format.html
	format.json { render :json=>clean_news }
      end
    end


    # GET /news_items/:id
    # GET /news_items/:id.json
    def show
      respond_to do |format|
        format.html # show.html.erb
        format.json { render :json => @news_item.ajax_attrs(@role) }
      end
    end

    # GET /news/year/month/day/seo-name
    # GET /news/year/month/day/seo-name.json
    def show_seo
    end

    # GET /news_item/new
    # GET /news_item/new.json
    def new
      authorize! :create, Roxiware::NewsItem
      @news_item =  Roxiware::NewsItem.new({:headline=>"Headline", :content=>"Content", :post_date=>DateTime.now.utc}, :as=>@role)
      respond_to do |format|
        format.html # new.html.erb
        format.json { render :json => @news_item.ajax_attrs(@role) }
      end
    end

    # POST /news_items
    # POST /news_items.json
    def create
      params[:post_date] = DateTime.now
      respond_to do |format|
        if @news_item.update_attributes(params, :as=>@role)
	   format.html { redirect_to @news_item, :notice => 'NewsItem was successfully updated.' }
           format.json { render :json => @news_item.ajax_attrs(@role) }
        else
	   format.html { redirect_to @news_item, :notice => 'Failure updating news_item.' }
           format.json { render :json=>report_error(@news_item)}
	end
      end
    end

    # PUT /news_items/:id
    # PUT /news_items/:id.json
    def update
      params[:post_date] = DateTime.now
      respond_to do |format|
        if @news_item.update_attributes(params, :as=>@role)
           format.html { redirect_to @news_item, :notice => 'NewsItem was successfully updated.' }
           format.json { render :json => @news_item.ajax_attrs(@role) }
        else
	   format.html { redirect_to @news_item, :notice => 'Failure updating news_item.' }
           format.json { render :json=>report_error(@news_item)}
         end
      end
    end

    def destroy
     respond_to do |format|
      if !@news_item.destroy
        format.json { render :json=>report_error(@news_item)}
      else
        format.json { render :json=>{}}
      end
     end
    end
  end
end