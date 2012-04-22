module Roxiware
   class PageController < ApplicationController

    def show
      @page = Page.where(:page_type=>params[:page_type]).first
      @title = @title + " : " + params[:page_type].capitalize
      @meta_description = @title
      @meta_keywords = @meta_keywords + ", " + params[:page_type]
      if @page.nil?
        @page = Page.new({:page_type=>params[:page_type], :content=>"New Content"})
      end
      @page["can_edit"] = can? :edit, @page
      respond_to do |format|
        format.html # show.html.erb
        format.json { render :json => @page }
      end
    end

    def update
      @page = Page.where(:page_type=>params[:page_type]).first
      if @page.nil?
        @page = Page.new({:page_type=>params[:page_type], :content=>"New Content"})
      end
      @page.content = params[:content]
      respond_to do |format|
        if @page.save()
          format.html { redirect_to @page, :notice => 'Page was successfully updated.' }
          format.json { render :json => @page }
        else
          format.html { redirect_to @page, :notice => 'Failure updating Page.' }
          format.json { head :fail }
        end
      end
    end
  end
end
