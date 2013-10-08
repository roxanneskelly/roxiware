require 'xml'
namespace :blog do
   namespace :wordpress do
      desc "Import Wordpress Export file"
      task :import, [:filename]=>:environment do |t, args|
	 parser = XML::Parser.file(args[:filename])
	 doc_obj = parser.parse
	 channel_obj = doc_obj.find_first("/rss/channel")
	 puts "IMPORTING #{channel_obj.find_first('title').content}, #{channel_obj.find_first('link').content} @ #{channel_obj.find_first('pubDate').content}"
	 site_link = channel_obj.find_first("link").content
         upload_path = File.join(site_link, 'wp-content', 'uploads').to_s

	 posts = channel_obj.find("item")
	 files = Set.new([])

	 posts.each do |post_item|
	     begin 
		 post_type = post_item.find_first("wp:post_type").content

		 
		 case post_type
		 when "post"
		     post = Roxiware::Blog::Post.new({:person_id=>1,
						  :blog_class=>"blog"}, :as=>"")
		     post.import_wp(post_item)
		     files.merge(URI.extract(post.post_content).select{|url| url.start_with?(upload_path)})
		     post.post_content.gsub!(/#{upload_path}\/\d+\/\d+/, AppConfig.upload_url) 
		     post.save!
                 when "page"
		     page = Roxiware::Page.new({:page_type=>"content", 
		                                :page_identifier=>post_item.find_first("title").content.to_seo,
						:content=>post_item.find_first("content:encoded").content}, :as=>"")
		     page.save!
		 when "attachment"
		     files <<  post_item.find_first("guid").content
                 else
		     puts "UNKNOWN POST ITEM TYPE #{post_type}"
                 end
             rescue Exception=>e
		 puts e.message
	     end
	 end
	 files.each do |asset_url|
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
      end
   end
end

