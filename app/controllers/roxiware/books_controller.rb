require 'xml'

class Roxiware::BooksController < ApplicationController
  application_name "books"

  include Roxiware::BooksHelper

  before_filter do
    @role = "guest"
    @role = current_user.role unless current_user.nil?
  end

  # GET /books
  # GET /books.json
  def index

    @page_title = @title + " : Books"

    series_ids = []
    authorize! :read, Roxiware::Book
    #series = Hash[Roxiware::BookSeries.all.collect{|series| [series.id, series]}]
    books = Roxiware::Book.includes(:book_series_joins).order("publish_date DESC")
    @books = books.select{|book| book.book_series_joins.blank?}
    books.each do |book|
       book.book_series_joins.each do |series_join|
          series_ids << series_join.book_series_id unless series_ids.include?(series_join.book_series_id)
       end
    end
    series_map = Hash[Roxiware::BookSeries.where(:id=>series_ids).collect{|series| [series.id, series]}]
    @series = series_ids.collect{|series| series_map[series]}
    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @books }
    end
  end

  # GET /books/1
  # GET /books/1.json
  def show

    @book = Roxiware::Book.where("isbn = ? OR isbn13 = ? OR seo_index = ? OR id = ?", params[:id], params[:id], params[:id], params[:id]).first
    raise ActiveRecord::RecordNotFound if @book.nil?
    authorize! :read, @book

    @page_title = @book.title
    @page_images = [@book.large_image_url, @book.image_url, @book.thumbnail_url]
    @meta_keywords = @meta_keywords + ", " + @book.title

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @book }
    end
  end

  # GET /books/import
  def import
    authorize! :create, Roxiware::Book
    result = []
    search_params = {}
    result = []

    goodreads = Roxiware::Goodreads::Book.new(:goodreads_user=>@goodreads_user)

    begin
	if params[:search].present?
	   # we're searching for a book.

	   if (match = params[:search].match(/^\s*([\dxX]{10}|\d{13})\s*/))
	       search_params[:isbn] = match[1]
	   else
	     begin
		 site_uri = URI.parse(params[:search])
		 if site_uri.host == "www.amazon.com"
		    if(match = site_uri.path.match(/\/gp\/product\/([\w]{10})/))
		       search_params[:asin]=match[1]
		    elsif(match = site_uri.path.match(/\/([\w-]+)\/dp\/([\w]{10})/))
		       search_params[:asin]=match[2]
		       search_params[:title]=match[1].sub(/_/, " ")
		    end
		 elsif site_uri.host == "www.goodreads.com"
		    match = site_uri.path.match(/\/book\/show\/(\d+)[\.-]([\w_-]+)/)
		    if(match)
		       search_params[:goodreads_id] = match[1]
		       search_params[:title]=match[2]
		    end
	      end
	      rescue
	      end
	   end
	   search_params[:title] = params[:search] if search_params.blank?
	   result = goodreads.search_books(search_params)
        elsif params[:goodreads_id].present?
	  result = goodreads.get_book(params[:goodreads_id]);
        end
    rescue  ::Roxiware::Goodreads::GoodreadsServerException=>e
      respond_to do |format|
        format.json { render :status => 406 }
      end
    end

    respond_to do |format|
      format.json { render :json => result }
    end

  end


  # GET /books/new
  # GET /books/new.json
  def new
    @robots="noindex,nofollow"
    authorize! :create, Roxiware::Book
    
    @book = Roxiware::Book.new
    if params[:goodreads_id]
       goodreads = Roxiware::Goodreads::Book.new(:goodreads_user=>@goodreads_user)
       @book.from_goodreads_book(goodreads.get_book(params[:goodreads_id]))
       @book.init_sales_links
    end

    respond_to do |format|
      format.html { render :partial =>"roxiware/books/editform" }
      format.json { render :json => @book.ajax_attrs(@role) }
    end
  end

  # GET /books/1/edit
  def edit
    @book = Roxiware::Book.find(params[:id])
    raise ActiveRecord::RecordNotFound if @book.nil?
    authorize! :edit, @book
    respond_to do |format|
      format.html { render :partial =>"roxiware/books/editform" }
    end
  end

  # POST /books
  # POST /books.json
  def create
    authorize! :create, @book
    if params[:book][:goodreads_id]
       goodreads_book = Roxiware::GoodreadsIdJoin.where(:goodreads_id=>params[:book][:goodreads_id]).first
       if goodreads_book
           @book = goodreads_book.grent
       end
    end
    if @book.blank?
        @book = Roxiware::Book.new
    end

    duplicate_book = Roxiware::Book.where(:seo_index=>params[:book][:title].to_seo).first
    index = 0
    while(duplicate_book.present?)
        index = index+1
        duplicate_book = Roxiware::Book.where(:seo_index=>(params[:book][:title]+" (#{index})").to_seo).first
    end
    if(index > 0) 
        params[:book][:title] = params[:book][:title]+" (#{index})"
    end

    success = _create_or_update(@book)
    respond_to do |format|
      if success
	format.xml  { render :xml => {:success=>true}}
	format.json  { render :json => {:success=>true, :book => @book.ajax_attrs(@role) }}
        format.html { redirect_to @book, :notice => 'Book was successfully created.' }

      else
        format.html { render :action => "edit" }
	format.xml  { head :fail }
        format.json { render :json => @book.errors, :status => :unprocessable_entity }
      end
    end
  end

  def _create_or_update(book)
    success = true
    ActiveRecord::Base.transaction do
       begin
	  if params[:book][:params].present?
	      book.get_param_objs.values.each do |param|
		 if params[:book][:params][param.name.to_sym].present?
		     param.value = params[:book][:params][param.name.to_sym]
		     param.save!
		 end
	      end
	  end
          if params[:format] == "xml"
	      parser = XML::Parser.io(request.body)
	      if parser.blank?
		  raise ActiveRecord::Rollback
	      end
	      doc = parser.parse
	      param_nodes = doc.find("/book/params/param")
	      param_nodes.each do |param_node|
		  param = book.get_param(param_node["name"])
		  param.destroy if param.present? && (param.param_object_type == "Roxiware::Book")
		  param = book.params.build
		  if param.blank?
			raise ActiveRecord::Rollback
		  end
		  param.import(param_node, false)
              end
	  end
          book.assign_attributes(params[:book], :as=>@role)
          book.save!
       rescue Exception => e
           print e.message
	   puts e.backtrace.join("\n")
	   success = false
       end
    end
    if(success)
       run_layout_setup
    end
    success
  end


  # PUT /books/1
  # PUT /books/1.json
  def update
    @book = Roxiware::Book.find(params[:id])
    raise ActiveRecord::RecordNotFound if @book.nil?
    authorize! :update, @book
    success = _create_or_update(@book)
    respond_to do |format|
      if success
	format.xml  { render :xml => {:success=>true}}
	format.json  { render :json => {:success=>true, :book => @book.ajax_attrs(@role) }}
        format.html { redirect_to @book, :notice => 'Book was successfully updated.' }

      else
        format.html { render :action => "edit" }
	format.xml  { head :fail }
        format.json { render :json => @book.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /books/1
  # DELETE /books/1.json
  def destroy
    @book = Roxiware::Book.find(params[:id])
    raise ActiveRecord::RecordNotFound if @book.nil?
    authorize! :read, @book
    @book.destroy
    run_layout_setup
    respond_to do |format|
      format.html { redirect_to books_url }
      format.json { head :no_content }
    end
  end
end
