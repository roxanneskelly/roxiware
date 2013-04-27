class Roxiware::PageController < ApplicationController

  application_name "pages"

  before_filter do
    @role = "guest"
    @role = current_user.role unless current_user.nil?
  end


  def application_path(params)
      params[:id]
  end

  def show
      page_type = params[:page_type] || "content"
      @page = Roxiware::Page.where(:page_type=>page_type, :page_identifier=>params[:id]).first
      @page ||=  Roxiware::Page.new({:page_type=>page_type, :page_identifier=>params[:id], :content=>""}, :as=>"") if can? :create, Roxiware::Page
      raise ActiveRecord::RecordNotFound if @page.nil?
      authorize!  :read, @page
      @page_identifier = "#{params[:id]}_page"
      @title = @title + " : " + @page.page_identifier.titleize
      @meta_keywords = @meta_keywords+", " + @page.page_identifier
      respond_to do |format|
        format.html # show.html.erb
        format.json { render :json => @page.ajax_attrs(@role) }
      end
    end

   def edit
      page_type = params[:page_type] || "content"
      @page = Roxiware::Page.where(:page_type=>page_type, :page_identifier=>params[:id]).first
      @page ||=  Roxiware::Page.new({:page_type=>page_type, :page_identifier=>params[:id], :content=>""}, :as=>"") if can? :create, Roxiware::Page
      raise ActiveRecord::RecordNotFound if @page.nil?
      respond_to do |format|
        format.html { render :partial=>"roxiware/page/editform" }
      end
    end

    def update
      page_type = params[:page_type] || "content"
      @page = Roxiware::Page.where(:page_type=>page_type, :page_identifier=>params[:id]).first
      @page ||=  Roxiware::Page.new({:page_type=>page_type, :page_identifier=>params[:id], :content=>""}, :as=>"") if can? :create, Roxiware::Page
      raise ActiveRecord::RecordNotFound if @page.nil?
      respond_to do |format|
        if @page.update_attributes(params[:page], :as=>@role)
          format.html { redirect_to page_path(@page.page_type), :notice => 'Page was successfully updated.' }
          format.json { render :json => @page.ajax_attrs(@role) }
        else
          format.html { redirect_to page_path(@page.page_type), :notice => 'Failure updating Page.' }
          format.json { render :json=>report_error(@page)}
        end
      end
    end
end
