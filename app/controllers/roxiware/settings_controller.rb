module Roxiware
  class SettingsController < ApplicationController
       skip_after_filter :store_location

       # settings edit page
       def show
          @application = params[:id]
          @settings = Hash[Roxiware::Param::Param.application_params(params[:id]).select{|param| can? :edit, param}.collect{|param| [param.name, param]}]
	  edit_file_root = params[:id]
	  edit_file_root = "default" unless File.file?("#{Roxiware::Engine.root}/app/views/roxiware/settings/_editform_#{edit_file_root}.html.erb")
          respond_to do |format|
	     format.html {render :partial => "roxiware/settings/editform_#{edit_file_root}"}
	     format.json {render :json =>settings}
	  end
       end

       def update
         setting_params = Roxiware::Param::Param.application_param_hash(params[:id])
         params[params[:id]].each do |key, value|
	     if setting_params[key] && can?(:edit, setting_params[key])
	          puts "SETTING #{params[:id]}/#{key} to #{value}"
	          Roxiware::Param::Param.set_application_param(params[:id], key, setting_params[key].description_guid, value)
             end
         end
	 refresh_layout	
	 run_layout_setup
         respond_to do |format|
            format.html { redirect_to return_to_location("/"), :notice => 'Settings were successfully updated.' }
            format.json { render :json => {} }
         end
       end

       def import
	   parser = XML::Parser.io(request.body)
	   doc_obj = parser.parse
	   channel_obj = doc_obj.find_first("/rss/channel")
	   puts "IMPORTING #{channel_obj.find_first('title').content}, #{channel_obj.find_first('link').content} @ #{channel_obj.find_first('pubDate').content}"
	   site_link = URI(channel_obj.find_first("link").content)

	   if(site_link.host.end_with?("wordpress.com"))
	       upload_path = "http://#{site_link.host.gsub(/wordpress\.com/, 'files.wordpress.com')}"
	   else
               upload_path = File.join(site_link, 'wp-content', 'uploads').to_s
	   end

	   posts = channel_obj.find("item")
	   assets = Set.new([])

	   posts.each do |post_item|
	       begin 
	           post_type = post_item.find_first("wp:post_type").content
		   
                   case post_type
		   when "post"
		       post = Roxiware::Blog::Post.new({:person_id=>1,
						  :blog_class=>"blog"}, :as=>"")
		       post.import_wp(post_item, current_user)
		       assets.merge(URI.extract(post.post_content).select{|url| url.start_with?(upload_path)})
		       post.post_content.gsub!(/#{upload_path}\/\d+\/\d+/, AppConfig.upload_url) 
		       post.save!
                   when "page"
		       page = Roxiware::Page.new({:page_type=>"content", 
		                                :page_identifier=>post_item.find_first("title").content.to_seo,
						:content=>post_item.find_first("content:encoded").content}, :as=>"")
		       page.save!
		   when "attachment"
		       assets <<  post_item.find_first("guid").content
                   else
		       puts "UNKNOWN POST ITEM TYPE #{post_type}"
                   end
               rescue Exception=>e
		   puts e.message
	       end
	   end
	   puts "ASSETS #{assets.inspect}"
	   assets.each do |asset_url|
	       uri = URI(asset_url)
	       Net::HTTP.start(uri.host, uri.port) do |http|
                   request = Net::HTTP::Get.new(uri.request_uri)
		   http.request request do |response|
		       target_filename = File.join(AppConfig.processed_upload_path, File.basename(uri.path)).to_s
		       open target_filename, 'w' do |io|
		           response.read_body do |chunk|
		               io.write chunk
			   end
	               end
	           end
               end
           end
           respond_to do |format|
	      # return json from xml call as that's what the file uploader is expecting
              format.xml { render :json=>{:success=>true}}
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