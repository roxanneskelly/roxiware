module Roxiware
  class NewsItemController < ApplicationController
    load_and_authorize_resource :except => [ :show_seo ]

    # GET /news_items
    # GET /news_items.json
    def index
      @enable_news_edit = true
      @news = NewsItem.find(:all, :order=>"post_date DESC")
      @title = @title + " : News"
      @meta_description = @title
      @news.each do |news_item| 
        @meta_keywords = @meta_keywords + ", " + news_item.headline
      end 
    end


    # GET /news_items/:id
    # GET /news_items/:id.json
    def show
      @news_item["can_edit"] = @news_item.writable_attribute_names(current_user)
      respond_to do |format|
        format.html # show.html.erb
        format.json { render :json => @news_item }
      end
    end

    # GET /news/year/month/day/seo-name
    # GET /news/year/month/day/seo-name.json
    def show_seo
    end

    # GET /news_item/new
    # GET /news_item/new.json
    def new
      @news_item["headline"] = "Headline"
      @news_item["content"] = "Content"
      @news_item["can_edit"] = @news_item.writable_attribute_names(current_user)
      respond_to do |format|
        format.html # new.html.erb
        format.json { render :json => @news_item.to_json }
      end
    end

    # POST /news_items
    # POST /news_items.json
    def create
      params[:post_date] = DateTime.now
      respond_to do |format|
        if @news_item.update_attributes(params, :as=>current_user.role)
	   format.html { redirect_to @news_item, :notice => 'NewsItem was successfully updated.' }
           format.json { render :json => @news_item }
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
        if @news_item.update_attributes(params, :as=>current_user.role)
           format.html { redirect_to @news_item, :notice => 'NewsItem was successfully updated.' }
           format.json { render :json => @news_item }
        else
	   format.html { redirect_to @news_item, :notice => 'Failure updating news_item.' }
           format.json { render :json=>report_error(@news_item)}
         end
      end
    end

    def destroy
      if !@news_item.destroy
        format.json { render :json=>report_error(@news_item)}
      else
        format.json { render :json=>{}}
      end
    end
  end
end