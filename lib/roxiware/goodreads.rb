module Roxiware
  module Goodreads

    class GoodreadsServerException < RuntimeError
      attr :message
      def initialize(message = nil)
	@message = message
      end
    end


    class Book
      include HTTParty
      base_uri "http://www.goodreads.com/"
      
      attr_accessor :goodreads_key, :goodreads_user

      def initialize(options = {})
        @goodreads_key = Roxiware.goodreads_key
	@goodreads_user = options[:goodreads_user]
      end

      def get_book(goodreads_id, options={})
        result = nil
        goodreads_options = options
        goodreads_options.merge!({:key=>@goodreads_key, :v=>2})
	goodreads_options[:format] = "xml"
	response = self.class.get("/book/show/"+goodreads_id.to_s, :query=>goodreads_options)
        raise ::Roxiware::Goodreads::GoodreadsServerException.new("Our book dataservice is currently offine.  Please try again later.") if response.blank? || response["GoodreadsResponse"].blank? || response["GoodreadsResponse"]["book"].blank?
        result_book = response["GoodreadsResponse"]["book"]

	_process_book(result_book)
      end


      def get_series(series_id, options = {})
         goodreads_options = options
         goodreads_options.merge!({:key=>@goodreads_key, :v=>2})
	 goodreads_options[:format] = "xml"

	 response = self.class.get("/series/"+series_id, :query=>goodreads_options)
         raise ::Roxiware::Goodreads::GoodreadsServerException.new("Our book dataservice is currently offine.  Please try again later.") if response.blank? || response["GoodreadsResponse"].blank? || response["GoodreadsResponse"]["series"].blank?
         result_series = response["GoodreadsResponse"]["series"]
	       
	 works = []
	 result_series["series_works"]["series_work"].each do |work_data|
	    order = work_data["user_position"]["__content__"]
	    parser = XML::Parser.io(StringIO.new(work_data["__content__"]))
	    doc = parser.parse
	    work_node = doc.find("//work//best_book").first
	    book_id = work_node.find_first("id").content
	    if(!options[:simple_book_info])
	       works << get_book(book_id, goodreads_options)
	    else
	       title = work_node.find_first('title').content
	       title=title.strip
	       author = {:author_name=>work_node.find_first('//author//name').content, :goodreads_id=>work_node.find_first('//author/id').content}
	       works << {:id=>work_node.find_first("id").content, :title=>title.strip, :authors=>[author]}
	    end
            works[-1][:order] = order
	 end
	 result = {:title=>result_series['title'], 
		       :goodreads_id=>series_id,
		       :books=>works,
		       :description=>result_series['description']}
	 result
	end

      # search for books
      def search_books(options={})
        result = []
        goodreads_options = {}
        goodreads_options.merge!({:key=>@goodreads_key, :v=>2})
	goodreads_options[:format] = "xml"
	if options[:goodreads_id].present?
	    response = self.class.get("/book/show/"+options[:goodreads_id], :query=>goodreads_options)
            raise ::Roxiware::Goodreads::GoodreadsServerException.new("Our book dataservice is currently offine.  Please try again later.") if response.blank? || response["GoodreadsResponse"].blank? || response["GoodreadsResponse"]["book"].blank?
            result_book = response["GoodreadsResponse"]["book"]
	    result << _process_book(result_book)	       
	end
	if(result.blank? && options[:isbn].present?)
	    goodreads_options[:isbn] = options[:isbn]
	    response = self.class.get("/book/isbn.xml", :query=>goodreads_options)
            raise ::Roxiware::Goodreads::GoodreadsServerException.new("Our book dataservice is currently offine.  Please try again later.") if response.blank? || response["GoodreadsResponse"].blank? || response["GoodreadsResponse"]["book"].blank?
	    result_book = response["GoodreadsResponse"]["book"]
	    result << _process_book(result_book)
	end
	if result.blank? && options[:asin].present?
	    goodreads_options[:isbn] = options[:asin]
	    response = self.class.get("/book/isbn.xml", :query=>goodreads_options)
            raise ::Roxiware::Goodreads::GoodreadsServerException.new("Our book dataservice is currently offine.  Please try again later.") if response.blank? || response["GoodreadsResponse"].blank? || response["GoodreadsResponse"]["book"].blank?
	    result_book = response["GoodreadsResponse"]["book"]
	    result << _process_book(result_book)
	end
	if result.blank? && options[:title].present?
	    goodreads_options[:q] = URI.escape(options[:title].gsub(" ", "+"))
	    response = self.class.get("/search.xml", :query=>goodreads_options)
            raise ::Roxiware::Goodreads::GoodreadsServerException.new("Our book dataservice is currently offine.  Please try again later.") if response.blank? || response["GoodreadsResponse"].blank? || response["GoodreadsResponse"]["search"].blank?
	    if(response["GoodreadsResponse"]["search"]["total_results"].to_i > 0)
               works = response["GoodreadsResponse"]["search"]["results"]["work"]
	       if works.class != Array
	          works = [works]
	       end
	       works.each do |work|
                   result_book = work['best_book']
		   result << _process_book(result_book)
                end
	    end
	end
	result
      end



      def search_series(options={})
        result = []
        goodreads_options = options
        goodreads_options.merge!({:key=>@goodreads_key, :v=>2, :simple_book_info=>true})
	goodreads_options[:format] = "xml"

        series_ids = Set.new()
        book_ids = []
	series_ids.add(options[:goodreads_id]) if options[:goodreads_id].present?

	if series_ids.blank?
	   book_search_options = options
	   options.delete(:goodreads_id)
	   options[:goodreads_id] = options[:goodreads_book_id]
	   book_search_results = search_books(book_search_options)
	   book_search_results.each do |book|
	      result_book = book
	      if book[:series_ids] == nil
	         result_book = get_book(book[:goodreads_id])
              end
	      series_ids.merge(result_book[:series_ids]) if result_book[:series_ids].present?
	   end
	end
	series_ids.each do |series_id|
	    result << get_series(series_id, goodreads_options);
	end
	result
      end

      def _process_book(result_book)
            authors = result_book['author']
	    if(authors.nil?)
	       authors = result_book['authors']['author']
	    end
	    if(authors.class == Hash)
	        authors=[authors]
	    end
	    large_image = result_book['image_url']
	    match = large_image.match(/(.*)m(\/\d+\.jpg)/)

	    if match
	       large_image = match[1]+"l"+match[2]
	    end

	    result = {    :title=>result_book['title'].strip, 
			  :image=>large_image,
			  :image=>result_book['image_url'],
			  :small_image=>result_book['small_image_url'],
			  :goodreads_id=>result_book['id'],
			  :isbn=>result_book['isbn'],
			  :isbn13=>result_book['isbn13'],
			  :description=>result_book['description'],
			  :authors=>authors.collect{|author| {:goodreads_id=>author['id'], :author_name=>author['name']}}}

	    if result_book["series_works"].present?
		if result_book["series_works"]["series_work"].class == Array
		   result[:series_ids] = result_book["series_works"]["series_work"].collect{|series_work| series_work["series"]["id"] }
		else
		   result[:series_ids] = [result_book["series_works"]["series_work"]["series"]["id"]]
		end
	    end
	    result
      end
    end

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
           raise ::Roxiware::Goodreads::GoodreadsServerException.new("Our book dataservice is currently offine.  Please try again later.") if response.blank? || response["GoodreadsResponse"].blank? || response["GoodreadsResponse"]["reviews"].blank?
	   response["GoodreadsResponse"]["reviews"]["review"]
       end
    end
  end
end