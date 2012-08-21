class Roxiware::PageController < ApplicationController

  before_filter do
    @role = "guest"
    @role = current_user.role unless current_user.nil?
  end


    def show
      @page = Roxiware::Page.where(:page_type=>params[:page_type]).first || Roxiware::Page.new({:page_type=>params[:page_type], :content=>"New Content"}, :as=>"")
      authorize!  :read, @page
      respond_to do |format|
        format.html # show.html.erb
        format.json { render :json => @page.ajax_attrs(@role) }
      end
    end

    def update
      @page = Roxiware::Page.where(:page_type=>params[:page_type]).first || Roxiware::Page.new({:page_type=>params[:page_type]}, :as=>"system")
      authorize! :edit, @page
      respond_to do |format|
        if @page.update_attributes(params, :as=>@role)
          format.html { redirect_to @page, :notice => 'Page was successfully updated.' }
          format.json { render :json => @page.ajax_attrs(@role) }
        else
          format.html { redirect_to @page, :notice => 'Failure updating Page.' }
          format.json { render :json=>report_error(@page)}
        end
      end
    end
end
