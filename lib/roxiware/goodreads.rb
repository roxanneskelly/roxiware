require 'xml'
require 'enumerator'
include Roxiware::Helpers
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


            def get_series(series_id, options = {})
                goodreads_options = options
                goodreads_options.merge!({:key=>@goodreads_key, :v=>2})
                goodreads_options[:format] = "xml"

                response = self.class.get("/series/"+series_id, :query=>goodreads_options)
                raise ::Roxiware::Goodreads::GoodreadsServerException.new("Our book dataservice is currently offine.  Please try again later.") if response.blank? || response["GoodreadsResponse"].blank? || response["GoodreadsResponse"]["series"].blank?
                result_series = response["GoodreadsResponse"]["series"]
                works = []
                result_series["series_works"]["series_work"].each do |work_data|
                    if(work_data.class != Array)
                        order = work_data["user_position"]["__content__"] if work_data["user_position"].present?
                        parser = ::XML::Parser.io(StringIO.new(work_data["__content__"]))
                        doc = parser.parse
                        work_node = doc.find("//work//best_book").first
                        book_id = work_node.find_first("id").content
                        if(!options[:simple_book_info])
                            works << get_book(book_id, goodreads_options)
                        else
                            title = work_node.find_first('title').content.strip
                            match = /^\s*([^\(]*).*/.match(title)
                            title = match[1] if match.present?
                            author = {:author_name=>work_node.find_first('//author//name').content, :goodreads_id=>work_node.find_first('//author/id').content}
                            works << {:id=>work_node.find_first("id").content, :title=>title, :authors=>[author]}
                        end
                        works[-1][:order] = order
                    end
                end
                works.sort!{|x, y| x[:order].to_f <=> y[:order].to_f}
                result = {:title=>result_series['title'].strip,
                    :goodreads_id=>series_id,
                    :books=>works,
                    :description=>result_series['description'] || ""}
                result
            end

            def search_series(options={})
                result = []
                goodreads_options = options
                goodreads_options.merge!({:key=>@goodreads_key, :v=>2, :simple_book_info=>true})
                goodreads_options[:format] = "xml"
                series_ids = Set.new()
                series_ids.add(options[:goodreads_id]) if options[:goodreads_id].present?

                if series_ids.blank? && options[:goodreads_author_id].present?
                    response = self.class.get("/series/list/#{options[:goodreads_author_id]}.xml", :query=>options)
                    raise ::Roxiware::Goodreads::GoodreadsServerException.new("Our book dataservice is currently offine.  Please try again later.") if response.blank? || response["GoodreadsResponse"].blank?
                    series_works = []
                    series_works = response["GoodreadsResponse"]["series_works"]["series_work"] if response["GoodreadsResponse"]["series_works"].present? &&response["GoodreadsResponse"]["series_works"]["series_work"].present?

                    if series_works.class == Hash
                        series_works = [series_works]
                    end

                    series_works.each do |series_work|
                        parser = ::XML::Parser.io(StringIO.new(series_work["__content__"]))
                        doc = parser.parse
                        work_node = doc.find("//work//best_book//author").first
                        work_node_book = doc.find("//work//best_book").first
                        author_id = work_node.find_first("id").content.to_i
                        if options[:goodreads_author_id].blank? || (options[:goodreads_author_id] == author_id)
                            series_ids.add(series_work["series"]["id"]["__content__"])
                        end
                    end
                end

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
                    current_series = get_series(series_id, goodreads_options)
                    if options[:goodreads_author_id].present?
                        # only add series if the author has contributed to most books
                        book_count = 0
                        current_series[:books].each do |book|
                            author_ids = book[:authors].collect{|author| author[:goodreads_id].to_i}
                            if book[:authors].collect{|author| author[:goodreads_id].to_i}.include? options[:goodreads_author_id]
                                book_count = book_count+1
                            end
                        end
                        if book_count > (current_series[:books].size/2)
                            result << current_series
                        end
                    else
                        result << current_series
                    end
                end
                result
            end



            def _process_book(result_book, options={})
                authors = result_book['author']
                options[:no_images] ||= false
                if(authors.nil?)
                    authors = result_book['authors']['author']
                end
                if(authors.class == Hash)
                    authors=[authors]
                end

                if !options[:no_images] && result_book['isbn'].present?
                    large_image = "http://covers.openlibrary.org/b/isbn/#{result_book['isbn']}-L.jpg?default=false"
                    image = "http://covers.openlibrary.org/b/isbn/#{result_book['isbn']}-M.jpg?default=false"
                    thumbnail_image = "http://covers.openlibrary.org/b/isbn/#{result_book['isbn']}-S.jpg?default=false"
                    response = Net::HTTP.get_response(URI.parse(large_image))
                    puts "CHECKING #{large_image} response #{response.inspect}"
                    if !(response == Net::HTTPFound || response == Net::HTTPOK)
                        large_image = nil
                        image = nil
                        thumbnail_image = nil
                    end
                end

                if (large_image.blank?)
                    large_image = result_book['image_url']
                    match = large_image.match(/(.*)m(\/\d+\.jpg)/)
                    if match
                        large_image = match[1]+"l"+match[2]
                    end
                    large_image = default_image_path(:book, "large") unless (large_image =~ /.*nocover.*/).nil?
                end
                if image.blank?
                    image = result_book['image_url']
                    image = default_image_path(:book, "small") unless (image =~ /.*nocover.*/).nil?
                end
                if thumbnail_image.blank?
                    thumbnail_image = result_book['small_image_url']
                    thumbnail_image = default_image_path(:book, "thumbnail") unless (thumbnail_image =~ /.*nocover.*/).nil?
                end

                title = result_book['title'].strip
                match = /^\s*([^\(]*).*/.match(title)
                title = match[1] if match.present?
                result = {:title=>title,
                    :large_image=>large_image,
                    :image=>image,
                    :thumbnail=>thumbnail_image,
                    :goodreads_id=>result_book['id'],
                    :publication_year=>(result_book['publication_year'] || 0).to_i,
                    :publication_day=>(result_book['publication_day'] || 1).to_i,
                    :publication_month=>(result_book['publication_month'] || 1).to_i,
                    :isbn=>result_book['isbn'],
                    :isbn13=>result_book['isbn13'],
                    :description=>result_book['description'] || "",
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

            def search_author(options={})
                result = []
                goodreads_options = {}
                goodreads_options.merge!({:key=>@goodreads_key, :v=>2})
                goodreads_options[:format] = "xml"

                author_ids = []
                author_ids << options[:goodreads_id] if options[:goodreads_id].present?

                # we don't have a direct author ID, so if we have a goodreads book ID, try that.
                if author_ids.blank?
                    if(options[:name].present?)
                        # search for author by name
                        response = self.class.get("/api/author_url/"+URI.escape(options[:name]), :query=>goodreads_options)
                        raise ::Roxiware::Goodreads::GoodreadsServerException.new("Our book dataservice is currently offine.  Please try again later.") if response.blank? || response["GoodreadsResponse"].blank?
                        author_ids << response["GoodreadsResponse"]["author"]["id"].to_i if response["GoodreadsResponse"]["author"].present?
                    end
                    if(options[:goodreads_book_id].present? || options[:title].present?)
                        # we do have a book id, so grab the author ids for the book.
                        book_options = options
                        book_options[:goodreads_id] = book_options[:goodreads_book_id] if book_options[:goodreads_book_id].present?
                        book_results = search_books(book_options)
                        book_results.each do |book|
                            if(book[:authors].present?)
                                book_authors = Set.new(book[:authors].collect{|author| author[:goodreads_id].to_i})
                                book_authors.subtract(author_ids)
                                author_ids = author_ids + book_authors.to_a
                            end
                        end
                    end
                end

                # grab info for each author
                author_ids.each do |author_id|
                    response = self.class.get("/author/show/#{author_id}.xml", :query=>goodreads_options)
                    raise ::Roxiware::Goodreads::GoodreadsServerException.new("Our book dataservice is currently offine.  Please try again later.") if response.blank? || response["GoodreadsResponse"].blank? || response["GoodreadsResponse"]["author"].blank?
                    author = response["GoodreadsResponse"]["author"]
                    books = []
                    goodreads_books = author["books"]["book"]
                    if goodreads_books.class == Hash
                        goodreads_books = [goodreads_books]
                    end
                    goodreads_books.each do |book|
                        books << _process_book(book, :no_images=>true)
                    end

                    author["small_image_url"] = default_image_path(:person, "thumbnail") unless (author["small_image_url"] =~ /.*nophoto.*/).nil?
                    author["image_url"] = default_image_path(:person, "thumbnail") unless (author["image_url"] =~ /.*nophoto.*/).nil?
                    author["large_image_url"] = default_image_path(:person, "large") unless (author["image_url"] =~ /.*nophoto.*/).nil?
                    result << {:goodreads_id=>author["id"],
                        :name=>author["name"],
                        :thumbnail=>author["small_image_url"],
                        :image=>author["small_image_url"],
                        :large_image=>author["image_url"],
                        :about=>author["about"] || "",
                        :books=>books}
                end
                result
            end

            def get_author_books(goodreads_id, options={})
                result = []
                goodreads_options = options
                page=1
                begin
                    goodreads_options.merge!({:key=>@goodreads_key, :v=>2})
                    goodreads_options[:format] = "xml"
                    goodreads_options[:page] = page
                    puts "GEt GOODREADS http://www.goodreads.com/author/list/#{goodreads_id}.xml?"+goodreads_options.to_query
                    response = self.class.get("/author/list/#{goodreads_id}.xml", :query=>goodreads_options)
                    raise ::Roxiware::Goodreads::GoodreadsServerException.new("Our book dataservice is currently offine.  Please try again later.") if response.blank? || response["GoodreadsResponse"].blank? || response["GoodreadsResponse"]["author"].blank? || response["GoodreadsResponse"]["author"]["books"].blank?
                    books = response["GoodreadsResponse"]["author"]["books"]["book"]
                    if (books.class == Hash)
                        books = [books]
                    end
                    books.each_slice(5) do |book_slice| 
                        result = result + book_slice.map{|book| Thread.start{_process_book(book)}}.map{|t| t.join.value}
                    end

                    page = page + 1
                end while response["GoodreadsResponse"]["author"]["books"]["end"] != response["GoodreadsResponse"]["author"]["books"]["total"]
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
