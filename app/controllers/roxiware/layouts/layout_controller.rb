require 'sass'
module Roxiware
  module Layouts
    class LayoutController < ApplicationController
       before_filter :_load_role, :unless=>[]
       skip_after_filter :store_location

       # Template chooser
       def index
	  @layouts = []
	  category_ids = Set.new([])
	  package_name = Roxiware::Param::Param.application_param_val("system", "hosting_package")
	  package_term = Roxiware::Terms::Term.where(:term_taxonomy_id=>Roxiware::Terms::TermTaxonomy.taxonomy_id(Roxiware::Terms::TermTaxonomy::LAYOUT_PACKAGE_NAME), :name=>package_name).first
	  Roxiware::Layout::Layout.joins(:term_relationships).where(:term_relationships=>{:term_id=>package_term.id}).each do |layout|
	     next if cannot? :read, layout
	     schemes = []
	     if(layout.get_param("schemes").present?)
		 layout.get_param("schemes").h.each do |scheme_id, scheme|
		    large_image_urls = scheme.h["large_images"].a.each.collect{|image| image.conv_value}
		    schemes << {:id=>scheme_id,
			      :name=>scheme.h["name"].to_s,
			      :thumbnail_image=>scheme.h["thumbnail_image"].to_s,
			      :large_images=>large_image_urls}
		 end
             end

	     category_ids.merge(layout.category_ids)
             schemes.sort!{|x,y| x[:name] <=> y[:name]}
	     layout_data = {:name=>layout.name,
			    :guid=>layout.guid,
			    :thumbnail_url=>layout.get_param("chooser_image").to_s,
			    :description=>layout.description,
			    :categories=>layout.category_ids,
			    :schemes=>schemes}
	     @layouts << layout_data
	  end
          @layouts.sort!{|x,y| x[:name] <=> y[:name]}

	  cat_tree_build = {}
          # grab the categories and sort them so lesser specific items will come before their contained categories
	  Roxiware::Terms::Term.where(:id=>category_ids.to_a).sort{|x, y| x.name <=> y.name}.each do |category|
	      # for the category, split off it's name and find the parent name
	      parent = category.name.split("/").reverse
	      parent.shift
	      
	      cat_tree_build[parent.reverse.join("/")] ||= []
	      cat_tree_build[parent.reverse.join("/")] << category
	  end
	  dfs = lambda do |current|
	     Hash[cat_tree_build[current].collect{|category| [category, dfs.call(category.name)]}] if cat_tree_build[current].present?
	  end

	  @categories = dfs.call("")
	  
	  respond_to do |format|
	     format.html {render :partial => "roxiware/templates/choose_template", :locals=>{:selected_scheme=>@layout_scheme, :selected_template=>@current_layout.guid} }
	     format.json {render :json =>@layouts}
	  end
       end

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
             format.xml { render :template=>"roxiware/templates/export" }
	   end
       end

       # GET /layout/:id/edit - edit form for a layout       
       def edit
           @layout = Roxiware::Layout::Layout.where(:guid=>params[:id]).first
	   raise ActiveRecord::RecordNotFound if @layout.nil?
	   authorize! :read, @layout
	   @params = []
 	   @param_descriptions = {}
	   @layout.get_param_objs.keys.collect{|key| key.to_s}.sort.each do |param_name|
	       param = @layout.get_param(param_name)
	       @params << param if ["local", "style"].include?(param.param_class)
               @param_descriptions[param.name] = param.description_guid
	   end
		 
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
             format.xml { render :template=>"roxiware/templates/export" }
	   end
       end

       # GET /layout/:id/edit - edit form for a layout       
       def new
           ActiveRecord::Base.transaction do
	      begin
		 @clone_id = params[:clone] || "00000000-0000-0000-0000-000000000000"
		 @clone_from_layout = Roxiware::Layout::Layout.where(:guid=>@clone_id).first
		 raise ActiveRecord::RecordNotFound if @clone_from_layout.nil?
		 authorize! :read, @clone_from_layout
		 authorize! :create, Roxiware::Layout::Layout
		 @layout = @clone_from_layout.deep_dup
		 
		 @params = []
		 @param_descriptions = {}
		 @layout.get_param_objs.keys.collect{|key| key.to_s}.sort.each do |param_name|
		    param = @layout.get_param(param_name)
	            @params << param if ["local", "style"].include?(param.param_class)
                    @param_descriptions[param.name] = param.description_guid
		 end
		 
		 @schemes = {}
		 @layout.get_param("schemes").h.each do |scheme_id, scheme|
		     large_image_urls = scheme.h["large_images"].a.each.collect{|image| image.conv_value}
		     @schemes[scheme_id] = {
					:name=>scheme.h["name"].to_s,
					:thumbnail_image=>scheme.h["thumbnail_image"].to_s,
					:large_images=>large_image_urls,
					:params=>scheme.h["params"].h}
		 end
		 
	      rescue Exception => e
	         puts e.message
		 puts e.backtrace.join("\n")
	         success = false
		 raise e
	      end
	   end
           respond_to do |format|
	     format.html { render :partial => "roxiware/templates/edit_layout_form" }
             format.xml { render :template=>"roxiware/templates/export" }
	   end
       end


       # PUT /layout/:guid
       def update
           @layout = Roxiware::Layout::Layout.where(:guid=>params[:id]).first
	   raise ActiveRecord::RecordNotFound if @layout.nil?
	   authorize! :update, @layout
           _update_or_create
       end
       
       # POST /layout
       def create
	   clone_id = params[:clone] || "00000000-0000-0000-0000-000000000000"
	   @clone_from_layout = Roxiware::Layout::Layout.where(:guid=>clone_id).first
	   raise ActiveRecord::RecordNotFound if @clone_from_layout.nil?
	   authorize! :read, @clone_from_layout
	   authorize! :create, Roxiware::Layout::Layout
	   @layout = @clone_from_layout.deep_dup
	   @layout.guid = params[:layout][:guid]
           _update_or_create
       end

       def _update_or_create
	   success = true
	   layout_data = params[:layout]
	   layout_param_data = layout_data[:params] || {}
	   layout_template_param_data = layout_data[:template_params] || {}
	   layout_param_descriptions = layout_data[:param_descriptions] || {}
	   layout_param_classes = layout_data[:param_classes] || {}
	   schemes = layout_data[:schemes]
	   layout_data.delete(:guid)

	   layout_params = {}
	   first_scheme = nil
           ActiveRecord::Base.transaction do
	      begin
	         layout_param_data.each do |name, value|
		     layout_params[name] = @layout.set_param(name, value, layout_param_descriptions[name], layout_param_classes[name])
		 end
	         layout_template_param_data.each do |name, value|
		     layout_params[name] = @layout.set_param(name, value, layout_param_descriptions[name], "template")
		 end
	         if schemes.present?
		     layout_schemes = @layout.set_param("schemes", {}, "62275C2A-29F9-4BAA-9893-BB0417917807", "scheme")
		     schemes.each do |scheme_id, scheme_data|
		        layout_scheme = layout_schemes.set_param(scheme_id, {}, "3E0D9787-B5C8-4883-882A-98BFAEEF7D53", "scheme")
		        layout_scheme_params = layout_scheme.set_param("params", {}, "2124E080-D791-4784-A89D-B1984DB73657", "scheme")

			scheme_params = scheme_data[:params]
			scheme_param_descriptions = scheme_data[:param_descriptions]
			current_scheme_params = {}
			if(scheme_params.present?) 
			    scheme_params.each do |name, value|
			        current_scheme_params[name] = layout_scheme_params.set_param(name, value, layout_param_descriptions[name], "style")
			    end
		        end
			first_scheme ||= current_scheme_params
		        layout_scheme.set_param("name", scheme_data[:name], "620EE4B4-2615-4B03-ADCB-FCC7198455AC", "scheme")
		        layout_scheme.set_param("thumbnail_image", scheme_data[:thumbnail_image], "0B092D47-0161-42C8-AEEC-6D7AA361CF1D", "scheme")
		        large_images = layout_scheme.set_param("large_images", [], "975967EA-A9BC-40EE-8E1B-7F3CA8089E66", "scheme")
			(scheme_data[:large_images] || []).each do |name, large_image|
			    large_images.set_param(name, large_image, "0B092D47-0161-42C8-AEEC-6D7AA361CF1D", "scheme")
			end
		     end
		 end
		 if !@layout.update_attributes(layout_data, :as=>@role)
		    raise ActiveRecord::Rollback
		 end
		 # Validate style.  It'd be nice to do this as a validator for
		 # the layout, but we need the context of the layout to check parameter
		 # changes to the layout
		 begin
		     style_params = {}
		     layout_params.each do |name, value|
		         style_params[name] = value if value.param_class=="style"
		     end

		     first_scheme ||= {}
		     syntax_check_params = first_scheme.merge(style_params)
		     Sass::Engine.new(@layout.eval_style(syntax_check_params).strip, {
				  :style=>:expanded,
				  :syntax=>:scss,
				  :cache=>false
			      }).render()
	         
		     begin
	                 run_layout_setup(@layout.setup)
	             rescue Exception => e
			success = false
		        puts e.backtrace.join("\n")
		        raise e
	             end
		 rescue Sass::SyntaxError => e
		    puts "#{e.message}  on line #{e.sass_line}"
		    puts e.sass_template
		    success = false
		    @layout.errors.add(:style, "#{e.message}  on line #{e.sass_line}")
		    raise ActiveRecord::Rollback
		 end
	      rescue ActiveRecord::Rollback
	         raise ActiveRecord::Rollback
	      rescue Exception => e
	         puts e.message
		 puts e.backtrace.join("\n")
	         success = false
	         @layout.errors.add(:setup, "#{e.message}")
		 raise ActiveRecord::Rollback
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