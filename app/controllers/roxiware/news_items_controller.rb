module Roxiware
  class NewsItemsController < ApplicationController
    include Roxiware::NewsItemsHelper

    load_and_authorize_resource :except => [ :index, :show, :show_seo ]

     def create_seo_index (fromstring)
       fromstring.downcase.gsub(/[^a-z0-9]+/i, '-')
     end

    # GET /news_items
    # GET /news_items.json
    def index
      store_location
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
      @news_item = NewsItem.find(params[:id])
      @news_item["can_edit"] = can? :edit, @news_item
      respond_to do |format|
        format.html # show.html.erb
        format.json { render :json => @news_item }
      end
    end

    # GET /news/year/month/day/seo-name
    # GET /news/year/month/day/seo-name.json
    def show_seo
      if (params[:id] == "new")
        @news_item = NewsItem.new
        @news_item["can_edit"] = can? :create, NewsItem
        @robots = "noindex,nofollow"
      else
        @news_item = NewsItem.find(params[:id])
        @news_item["can_edit"] = can? :edit, @news_item
        @title = @title + " : News : " + @news_item.headline
        @meta_description = @title
        @meta_keywords = @meta_keywords + ", " + @news_item.headline
      end
      respond_to do |format|
        format.html # show.html.erb
        format.json { render :json => @news_item }
      end
    end

    # GET /news_items/new
    # GET /news_items/new.json
    def new
      @news_item = NewsItem.new.attributes
      @news_item["headline"] = "Headline"
      @news_item["content"] = "Content"
      @news_item["can_edit"] = can? :create, NewsItem
      respond_to do |format|
        format.html # new.html.erb
        format.json { render :json => @news_item.to_json }
      end
    end



    # POST /news_items
    # POST /news_items.json
    def create
      @news_item = NewsItem.new({:post_date => DateTime.now})
      ["headline", "content"].each do |attribute_name|
          @news_item[attribute_name] = params[attribute_name]
      end
      @news_item.seo_index = create_seo_index(@news_item.headline)
      respond_to do |format|
        if(@news_item.headline.nil? || @news_item.headline == "") 
            format.html { redirect_back_or_default "/", :notice=>"You must have a headline" }
	    format.json { head :fail }
        else
	   if @news_item.save()
	      format.html { redirect_to @news_item, :notice => 'NewsItem was successfully updated.' }
              format.json { render :json => @news_item }
           else
	      format.html { redirect_to @news_item, :notice => 'Failure updating news_item.' }
	      format.json { head :fail }
	   end
         end
      end
    end

    # PUT /news_items/:id
    # PUT /news_items/:id.json
    def update
      @news_item = NewsItem.find(params[:id])
      ["headline", "content"].each do |attribute_name|
          @news_item[attribute_name] = params[attribute_name]
      end
      @news_item.seo_index = create_seo_index(@news_item.headline)
      respond_to do |format|
         if(@news_item.headline.nil? || @news_item.headline == "") 
             format.html { redirect_back_or_default "/", :notice=>"You must have a headline" }
	     format.json { head :fail }
         else
             @news_item.seo_index = create_seo_index(@news_item.headline)
             if @news_item.save()
	        format.html { redirect_to @news_item, :notice => 'NewsItem was successfully updated.' }
                format.json { render :json => @news_item }
             else
	        format.html { redirect_to @news_item, :notice => 'Failure updating news_item.' }
	        format.json { head :fail }
	     end
         end
      end
    end


    def destroy
      @news_item = NewsItem.find(params[:id])
      @news_item.destroy
      respond_to do |format|
        format.html { redirect_to news_items_url }
        format.json { head :ok }
      end
    end
  end
end