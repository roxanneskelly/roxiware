module Roxiware
  module Goodreads
    class Review
      include HTTParty
      base_uri "http://www.goodreads.com/review/"
      
       def list(options={})
           options.merge!({:key=>AppConfig::goodreads_key, :v=>2})
	   response = self.class.get("/list/#{AppConfig::goodreads_user}.xml", :query=>options)
	   response["GoodreadsResponse"]["reviews"]["review"]
       end
    end
  end
end