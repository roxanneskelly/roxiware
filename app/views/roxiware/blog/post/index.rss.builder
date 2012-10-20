xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    xml.title @blog_title
    xml.description @blog_description
    xml.link url_for(:only_path=>false)
    copyright_years = (@site_copyright_first_year != DateTime.now.year.to_s)? @site_copyright_first_year:""
    xml.copyright copyright_years + " © " +  @site_copyright
    xml.docs "http://www.rssboard.org/rss-specification"
    xml.generator "Roxiware Blog Services"
    #xml.image do
    #  xml.link request.path+"/blog"
    #  xml.title @blog_title
    #  xml.url image_path("blog_image.png")
    #  xml.description @blog_description
    #end
    xml.language @blog_language
    xml.managingEditor @blog_editor_email
    xml.webMaster @webmaster_email
    @posts.each do |post|
      xml.item do
        xml.title post.post_title
        xml.description post.post_exerpt
        xml.pubDate post.post_date.to_s(:rfc822)
        xml.link "http://#{request.host_with_port}#{post.post_link}"
        xml.guid("http://#{request.host_with_port}#{post.post_link}", :isPermaLink=>"true")
      end
    end
  end
end

