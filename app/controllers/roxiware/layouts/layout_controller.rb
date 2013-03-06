module Roxiware
  module Layouts
    class LayoutController < ApplicationController
       before_filter :_load_role, :unless=>[]
       skip_after_filter :store_location

       # list all layouts
       def index
	  @layouts = []
	  category_ids = Set.new([])
	  Roxiware::Layout::Layout.all.each do |layout|
	     next if cannot? :read, layout
	     layout_schemes = []
	     layout.get_param("layout_schemes").h.each do |scheme_id, scheme|
		large_image_urls = scheme.h["large_images"].a.each.collect{|image| image.conv_value}
		layout_schemes << {:id=>scheme_id,
			  :name=>scheme.h["name"].to_s,
			  :thumbnail_url=>scheme.h["thumbnail_image"].to_s,
			  :large_images=>large_image_urls}
	     end

	     categories=layout.terms(:term_taxonomy_id=>Roxiware::Terms::TermTaxonomy.taxonomy_id(Roxiware::Terms::TermTaxonomy::LAYOUT_CATEGORY_NAME)).collect{|category| category.id}
	     category_ids.merge(categories)
	     layout_data = {:name=>layout.name,
			    :guid=>layout.guid,
			    :thumbnail_url=>layout.get_param("chooser_image").to_s,
			    :description=>layout.description,
			    :categories=>categories,
			    :layout_schemes=>layout_schemes}
	     @layouts << layout_data
	  end
	  @categories = Roxiware::Terms::Term.where(:id=>category_ids.to_a)

	  respond_to do |format|
	     format.html {render :partial => "roxiware/templates/choose_template" }
	     format.json {render :json =>@layouts}
	  end
       end

       # PUT /layouts - layout settings
       def settings
            Roxiware::Param::Param.set_application_param("system", "current_template", "B8A73EF2-9C65-4022-ABD3-2D4063827108", params[:template_guid])
            Roxiware::Param::Param.set_application_param("system", "layout_scheme", "99FA5423-147C-4929-A432-268BDED6DE44", params[:template_scheme])
	    refresh_layout
	    respond_to do |format|
	       format.json {render :json =>{:layout_guid=>params[:layout_guid], :layout_scheme=>params[:layout_scheme]}}
	    end
       end
       
       def show
           @layout = Roxiware::Layout::Layout.where(:guid=>params[:id]).first
	   raise ActiveRecord::RecordNotFound if @layout.nil?
	   authorize! :read, @layout
           respond_to do |format|
	     format.html { render :partial => "roxiware/shared/edit_layout_form" }
	   end
       end

       def update
           @layout = Roxiware::Layout::Layout.where(:guid=>params[:id]).first
	   raise ActiveRecord::RecordNotFound if @layout.nil?
	   authorize! :update, @layout
	   success = true
           ActiveRecord::Base.transaction do
	      begin
	         if params[:params].present?
	            @layout.params.each do |layout_param|
		       if params[:params][layout_param.name.to_sym].present?
		          layout_param.value = params[:params][layout_param.name.to_sym]
			  layout_param.save!
		       end
		    end
		 end
		 if !@layout.update_attributes(params, :as=>@role)
		    raise ActiveRecord::Rollback
		 end 
	      rescue Exception => e
	         print e.message
	         success = false
	      end
           end

	   respond_to do |format|
	       if success
		  refresh_layout
		  format.xml  { render :xml => {:success=>true} }
		  format.html { redirect_to return_to_location("/"), :notice => 'layout was successfully updated.' }
		  format.json { render :json => @layout.ajax_attrs(@role) }
	       else
		  format.html { redirect_to return_to_location("/"), :alert => 'Failure updating layout.' }
		  format.xml  { head :fail }
		  format.json { render :json=>report_error(@layout)}
	       end
	   end
       end

     private
       def _load_role
	   @role = "guest"
	   @role = current_user.role unless current_user.nil?
	   @person_id = (current_user && current_user.person)?current_user.person.id : -1
       end
    end
  end
end