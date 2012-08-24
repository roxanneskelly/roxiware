require 'date'
namespace :blog do
   namespace :pull do
      desc "Pull blog data from an rss feed"
      task :rss, [:url]=>:environment do |t|
	 puts "URL is #{args[:url]}"
	 response = HTTParty.get(args[:url])
	 blog_data = Hash.from_xml(response.body)
	 blog_data["feed"]["entry"].each do |entry|
            tags = ""
	    categories = entry["category"]
	    categories = [categories] if categories.class != Array
	    tags = categories.select{|category| (category.has_key?("term") && (!category["term"].blank?))}.collect{|category| category["term"]}.join(",") if !entry["category"].blank?
	    post = Roxiware::Blog::Post.new({:post_title=>entry["title"], :post_content=>entry["content"], :tag_csv=>tags, :person_id=>2, :post_status=>"publish", :post_date=>::DateTime.parse(entry["published"])}, :without_protection=>true)
	    post.save
	 end
      end
   end
end

