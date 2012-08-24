xml.instruct! :xml, :version =>"1.0"
xml.urlset(:xmlns=>"http://www.sitemaps.org/schemas/sitemap/0.9") do
  # home page
  xml.url do
     xml.loc "http://#{request.host_with_port}/"
     xml.changefreq "daily"
     xml.priority 1.0
   end
   
   # blog
   if Roxiware.enable_blog
     @posts.each do |post|
      xml.url do
        xml.lastmod  post.updated_at.strftime("%Y-%m-%d")
        xml.changefreq "weekly"
        xml.priority "0.5"
	xml.loc "http://#{request.host_with_port}#{post.post_link}"
      end
    end
   end
   
   # bio/people
   if Roxiware.enable_people
      if Roxiware.single_person
        xml.url do
	   xml.lastmod @person.updated_at.strftime("%Y-%m-%d")
	   xml.changefreq "weekly"
	   xml.priority "1.0"
	   xml.loc "http://#{request.host_with_port}/about"
	end
      else
         @people.each do |person|
	   xml.lastmod person.updated_at.strftime("%Y-%m-%d")
	   xml.changefreq "weekly"
	   xml.priority "1.0"
	   xml.loc "http://#{request.host_with_port}/people/#{person.seo_index}"
	 end
      end
   end
end
