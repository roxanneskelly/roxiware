xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    xml.title Roxiware.blog_title
    xml.description Roxiware.blog_description
    xml.link request.path+"/blog"
    xml.copyright DateTime.now.year.to_s + " " +  ::AppConfig.copyright
    xml.docs "http://www.rssboard.org/rss-specification"
    xml.generator "Roxiware Blog Services"
    xml.image do
      xml.link request.path+"/blog"
      xml.title Roxiware.blog_title
      xml.url image_path("blog_image.png")
      xml.description Roxiware.blog_description
    end
    xml.language Roxiware.blog_language
    xml.managingEditor ::AppConfig.company_email
    xml.webMaster ::AppConfig.company_email
    @posts.each do |post|
      xml.item do
        xml.title post.post_title
        xml.description post.post_content
        xml.pubDate post.post_date.to_s(:rfc822)
        xml.link "http://#{request.host_with_port}#{post.post_link}"
        xml.guid("http://#{request.host_with_port}#{post.post_link}", :isPermaLink=>"true")
	xml.exerpt post.post_exerpt
      end
    end
  end
end

