module Roxiware
  module Layouts
    class LayoutController < ApplicationController
       before_filter :_load_role, :unless=>[]
       skip_after_filter :store_location

       # Template chooser
       def index
	  @layouts = []
	  category_ids = Set.new([])
	  Roxiware::Layout::Layout.all.each do |layout|
	     next if cannot? :read, layout
	     schemes = []
	     layout.get_param("schemes").h.each do |scheme_id, scheme|
		large_image_urls = scheme.h["large_images"].a.each.collect{|image| image.conv_value}
		schemes << {:id=>scheme_id,
			  :name=>scheme.h["name"].to_s,
			  :thumbnail_image=>scheme.h["thumbnail_image"].to_s,
			  :large_images=>large_image_urls}
	     end

	     categories=layout.terms(:term_taxonomy_id=>Roxiware::Terms::TermTaxonomy.taxonomy_id(Roxiware::Terms::TermTaxonomy::LAYOUT_CATEGORY_NAME)).collect{|category| category.id}
	     category_ids.merge(categories)
	     layout_data = {:name=>layout.name,
			    :guid=>layout.guid,
			    :thumbnail_url=>layout.get_param("chooser_image").to_s,
			    :description=>layout.description,
			    :categories=>categories,
			    :schemes=>schemes}
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

       # GET /layout/:id - edit form for a layout       
       def show
           @layout = Roxiware::Layout::Layout.where(:guid=>params[:id]).first
	   raise ActiveRecord::RecordNotFound if @layout.nil?
	   authorize! :read, @layout
	   @schemes = {}
	   @layout.get_param("schemes").h.each do |scheme_id, scheme|
	       large_image_urls = scheme.h["large_images"].a.each.collect{|image| image.conv_value}
	       @schemes[scheme_id] = {
	                          :name=>scheme.h["name"].to_s,
			          :thumbnail_image=>scheme.h["thumbnail_image"].to_s,
			          :large_images=>large_image_urls,
				  :params=>scheme.h["params"].h}
	     end
           respond_to do |format|
	     format.html { render :partial => "roxiware/templates/edit_layout_form" }
	   end
       end

       def update
           @layout = Roxiware::Layout::Layout.where(:guid=>params[:id]).first
	   raise ActiveRecord::RecordNotFound if @layout.nil?
	   authorize! :update, @layout
	   success = true
	   layout_data = params[:layout]
	   layout_params = layout_data[:params]
	   layout_param_descriptions = layout_data[:param_descriptions]
	   schemes = layout_data[:schemes]

           ActiveRecord::Base.transaction do
	      begin
	         layout_params.each do |name, value|
		     @layout.set_param(name, value, layout_param_descriptions[name])
		 end
	         if schemes.present?
		     layout_schemes = @layout.set_param("schemes", nil, "62275C2A-29F9-4BAA-9893-BB0417917807", "scheme")
		     schemes.each do |scheme_id, scheme_data|
		        layout_scheme = layout_schemes.set_param(scheme_id, nil, "3E0D9787-B5C8-4883-882A-98BFAEEF7D53", "scheme")
		        layout_scheme_params = layout_scheme.set_param("params", nil, "2124E080-D791-4784-A89D-B1984DB73657", "scheme")

			scheme_params = scheme_data[:params]
			scheme_param_descriptions = scheme_data[:param_descriptions]
			scheme_params.each do |name, value|
			    layout_scheme_params.set_param(name, value, scheme_param_descriptions[name], "style") 
			end
		     
		        layout_scheme.set_param("name", scheme_data[:name], "620EE4B4-2615-4B03-ADCB-FCC7198455AC", "scheme")
		        layout_scheme.set_param("thumbnail_image", scheme_data[:thumbnail_image], "0B092D47-0161-42C8-AEEC-6D7AA361CF1D", "scheme")
		        large_images = layout_scheme.set_param("large_images", nil, "975967EA-A9BC-40EE-8E1B-7F3CA8089E66", "scheme")
			(scheme_data[:large_images] || []).each do |name, large_image|
			    large_images.set_param(name, large_image, "0B092D47-0161-42C8-AEEC-6D7AA361CF1D", "scheme")
			end
		     end
		 end
		 if !@layout.update_attributes(layout_data, :as=>@role)
		    raise ActiveRecord::Rollback
		 end 
	      rescue Exception => e
	         puts e.message
		 puts e.backtrace.join("\n")
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