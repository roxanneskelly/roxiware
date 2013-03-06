class Roxiware::PageController < ApplicationController


  application_name "pages"

  before_filter do
    @role = "guest"
    @role = current_user.role unless current_user.nil?
  end


  def show
      @page = Roxiware::Page.where(:page_type=>params[:id]).first || Roxiware::Page.new({:page_type=>params[:id], :content=>""}, :as=>"")
      @title = @title + " : " + @page.page_type.titleize
      @meta_keywords = @meta_keywords+", " + @page.page_type
      authorize!  :read, @page
      respond_to do |format|
        format.html # show.html.erb
        format.json { render :json => @page.ajax_attrs(@role) }
      end
    end

   def edit
      @page = Roxiware::Page.where(:page_type=>params[:id]).first || Roxiware::Page.new({:page_type=>params[:id], :content=>""}, :as=>"")
      authorize!  :edit, @page
      respond_to do |format|
        format.html { render :partial=>"roxiware/page/editform" }
      end
    end

    def update
      @page = Roxiware::Page.where(:page_type=>params[:id]).first || Roxiware::Page.new({:page_type=>params[:id], :content=>""}, :as=>"")
      authorize!  :edit, @page
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
