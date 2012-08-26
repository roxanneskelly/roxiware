module Roxiware
  module Goodreads
    class Review
      include HTTParty
      base_uri "http://www.goodreads.com/review/"
      
      attr_accessor :goodreads_key, :goodreads_user

      def initialize(options = {})
        @goodreads_key = Roxiware.goodreads_key
	@goodreads_user = options[:goodreads_user]
      end

      def list(options={})
           options.merge!({:key=>@goodreads_key, :v=>2})
	   response = self.class.get("/list/#{@goodreads_user}.xml", :query=>options)
	   response["GoodreadsResponse"]["reviews"]["review"]
       end
    end
  end
end