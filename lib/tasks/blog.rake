require 'xml'
namespace :blog do
    namespace :wordpress do
      desc "Export Wordpress"
      task :export, [:filename]=>:environment do |t, args|
            xml = ::Builder::XmlMarkup.new(:target=>$stdout)
            xml.instruct! :xml, :version => "1.0"
            xml.rss(:version=>"2.0", "xmlns:excerpt"=>"http://wordpress.org/export/1.2/excerpt/", "xmlns:content"=>"http://purl.org/rss/1.0/modules/content/", "xmlns:wfw"=>"http://wellformedweb.org/CommentAPI/",  "xmlns:dc"=>"http://purl.org/dc/elements/1.1/",  "xmlns:wp"=>"http://wordpress.org/export/1.2/" ) do |rss|
                xml << "\n"
                rss.channel do |channel|
                    channel << "\n"
                    channel.tag!("wp:wxr_version", "1.2" )
                    Roxiware::Blog::Post.all.each do |post_item|
                        channel.item do |item|
                            item << "\n"
                            item.title(post_item.post_title)
                            item << "\n"
                            item.tag!("wp:post_name") { |b| b.cdata!(post_item.post_title.to_seo) }
                            item << "\n"
                            item.tag!("dc:creator") { |b| b.cdata!("roxanne")}
                            item << "\n"
                            item.description
                            item << "\n"
                            item.tag!("content:encoded"){ |b| b.cdata!(post_item.post_content) }
                            item << "\n"
                            item.tag!("excerpt:encoded") { item.cdata!(post_item.post_exerpt) }
                            item << "\n"
                            item.tag!("wp:post_date") { |b| b.cdata!(post_item.post_date.strftime("%Y-%m-%d %H:%M:%S"))}
                            item << "\n"
                            item.tag!("wp:post_date_gmt") { |b| b.cdata!(post_item.post_date.strftime("%Y-%m-%d %H:%M:%S"))}
                            item << "\n"
                            item.tag!("wp:status") { |b| b.cdata!("pending")}
                            item << "\n"
                            item.tag!("wp:comment_status") { |b| b.cdata!("closed")}
                            item << "\n"
                            item.tag!("wp:post_type") { |b| b.cdata!("post")}
                            item << "\n"
                        end
                        channel << "\n"
                    end
                end
            end
      end

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

