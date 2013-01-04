require 'xml'

class Roxiware::BooksController < ApplicationController
  include Roxiware::BooksHelper

  before_filter do
    @role = "guest"
    @role = current_user.role unless current_user.nil?
  end

  # GET /books
  # GET /books.json
  def index
    authorize! :read, Roxiware::Book
    @series = Roxiware::BookSeries.all
    @books = Roxiware::Book.joins("left join book_series_joins bsj on books.id = bsj.book_id").where("bsj.id is null")

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
    @book = Roxiware::Book.new

    success = true
    ActiveRecord::Base.transaction do
       begin
	  if params[:book][:params].present?
	      @book.get_param_objs.values.each do |param|
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
		  param = @book.get_param(param_node["name"])
		  param.destroy if param.present? && (param.param_object_type == "Roxiware::Book")
		  param = @book.params.build
		  if param.blank?
			raise ActiveRecord::Rollback
		  end
		  param.import(param_node, false)
              end
	  end
	  if !@book.update_attributes(params[:book], :as=>@role)
	      raise ActiveRecord::Rollback
	  end 
       rescue Exception => e
           print e.message
	   success = false
       end
    end


    respond_to do |format|
      if success
	format.xml  { render :xml => {:success=>true} }
        format.html { redirect_to @book, :notice => 'Book was successfully created.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
	format.xml  { head :fail }
        format.json { render :json => @book.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /books/1
  # PUT /books/1.json
  def update
    @book = Roxiware::Book.find(params[:id])
    raise ActiveRecord::RecordNotFound if @book.nil?
    authorize! :update, @book
    success = true
    ActiveRecord::Base.transaction do
       begin
	  if params[:book][:params].present?
	      @book.get_param_objs.values.each do |param|
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
		  param = @book.get_param(param_node["name"])
		  param.destroy if param.present? && (param.param_object_type == "Roxiware::Book")
		  param = @book.params.build
		  if param.blank?
			raise ActiveRecord::Rollback
		  end
		  param.import(param_node, false)
              end
	  end
	  if !@book.update_attributes(params[:book], :as=>@role)
	      raise ActiveRecord::Rollback
	  end 
       rescue Exception => e
           print e.message
	   success = false
       end
    end
    respond_to do |format|
      if success
	format.xml  { render :xml => {:success=>true} }
        format.html { redirect_to @book, :notice => 'Book was successfully updated.' }
        format.json { head :no_content }
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

    respond_to do |format|
      format.html { redirect_to books_url }
      format.json { head :no_content }
    end
  end
end
