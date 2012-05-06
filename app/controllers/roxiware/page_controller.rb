class Roxiware::PageController < ApplicationController
    def show
      @page = Roxiware::Page.where(:page_type=>params[:page_type]).first || Roxiware::Page.new({:page_type=>params[:page_type], :content=>"New Content"}, :as=>"system")
      render :status => :unauthorized unless can? :read, @page
      @title = @title + " : " + params[:page_type].capitalize
      @meta_description = @title
      @meta_keywords = @meta_keywords + ", " + params[:page_type]
      @page["can_edit"] = @page.writeable_attribute_names(current_user)
      respond_to do |format|
        format.html # show.html.erb
        format.json { render :json => @page }
      end
    end

    def update
      @page = Roxiware::Page.where(:page_type=>params[:page_type]).first || Roxiware::Page.new({:page_type=>params[:page_type]}, :as=>"system")
      render :status => :unauthorized unless can? :edit, @page
      respond_to do |format|
        if @page.update_attributes(params, :as=>current_user.role)
          format.html { redirect_to @page, :notice => 'Page was successfully updated.' }
          format.json { render :json => @page }
        else
          format.html { redirect_to @page, :notice => 'Failure updating Page.' }
          format.json { render :json=>report_error(@page)}
        end
      end
    end
end
