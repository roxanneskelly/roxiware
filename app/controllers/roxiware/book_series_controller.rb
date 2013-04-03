require 'xml'
require 'set'

class Roxiware::BookSeriesController < ApplicationController
  before_filter do
    @role = "guest"
    @role = current_user.role unless current_user.nil?
  end

  # GET /books/series
  # GET /books/series.json
  def index
    authorize! :read, Roxiware::BookSeries
    @series = Roxiware::BookSeries.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @series }
    end
  end

  # GET /books/series/1
  # GET /books/series/1.json
  def show
    @series = Roxiware::BookSeries.where(:seo_index=>params[:id]).first
    raise ActiveRecord::RecordNotFound if @series.nil?
    authorize! :read, @series

    respond_to do |format|
      format.html { render :template=>"roxiware/books/series/show"}
      format.json { render :json => @series }
    end
  end

  # GET /books/series/import
  def import
    authorize! :create, Roxiware::BookSeries
    result = []
    search_params = {}
    result = []

    goodreads = Roxiware::Goodreads::Book.new(:goodreads_user=>@goodreads_user)

    if params[:search].present?
       # we're searching for a series.
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
	         if(match = site_uri.path.match(/\/book\/show\/(\d+)[\.-]([\w_-]+)/))
		    search_params[:goodreads_book_id] = match[1]
		    search_params[:title]=match[2]
	         elsif(match = site_uri.path.match(/\/series\/(\d+)[\.-]([\w_-]+)/))
		    search_params[:goodreads_id] = match[1]
		    search_params[:title]=match[2]
		 end
	      end
	  rescue
         end
       end
       search_params[:title] = params[:search] if search_params.blank?
       result = goodreads.search_series(search_params)
    elsif params[:goodreads_id].present?
       result = goodreads.get_series(params[:goodreads_id]);
    end

    respond_to do |format|
      format.json { render :json => result }
    end

  end


  # GET /books/series/new
  # GET /books/series/new.json
  def new
    @robots="noindex,nofollow"
    authorize! :create, Roxiware::BookSeries
    

    @series = Roxiware::BookSeries.new
    if params[:goodreads_id]
       goodreads = Roxiware::Goodreads::Book.new(:goodreads_user=>@goodreads_user)
       @series.from_goodreads_series(goodreads.get_series(params[:goodreads_id]))
    end
    @books = Roxiware::Book.all

    respond_to do |format|
      format.html { render :partial =>"roxiware/books/series/editform" }
      format.json { render :json => @series.ajax_attrs(@role) }
    end
  end

  # GET /books/series/1/edit
  def edit
    @series = Roxiware::BookSeries.find(params[:id])
    raise ActiveRecord::RecordNotFound if @series.nil?
    authorize! :edit, @series
    @books = Roxiware::Book.all
    respond_to do |format|
      format.html { render :partial =>"roxiware/books/series/editform" }
    end
  end

  # POST /books/series
  # POST /books/series.json
  def create

    respond_to do |format|
      if _create_or_update()
	format.xml  { render :xml => {:success=>true} }
        format.html { redirect_to @book_series, :notice => 'Book was successfully created.' }
        format.json { head :no_content }
      else
        format.html { render :action => "new" }
	format.xml  { render :xml=> @book_series.errors, :status => :unprocessable_entity }
        format.json { render :json => @book_series.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /books/series/1
  # PUT /books/series/1.json
  def update

    respond_to do |format|
      if _create_or_update()
	format.xml  { render :xml => {:success=>true} }
        format.html { redirect_to @book_series, :notice => 'Book was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
	format.xml  { head :fail }
        format.json { render :json => @book_series.errors, :status => :unprocessable_entity }
      end
    end
  end

  def _create_or_update()
    success = true
    if(params[:id].present?)
	@book_series = Roxiware::BookSeries.find(params[:id])
	raise ActiveRecord::RecordNotFound if @book_series.nil?
	authorize! :update, @book_series
    elsif params[:book_series][:goodreads_id].present?
       series_join = Roxiware::GoodreadsIdJoin.where(:goodreads_id=>params[:book_series][:goodreads_id]).first
       @book_series = series_join.grent
    end
    if(@book_series.blank?)
	authorize! :create, Roxiware::BookSeries
	@book_series = Roxiware::BookSeries.new
    end

    ActiveRecord::Base.transaction do
       begin
	  if params[:book_series][:params].present?
	      book_series.get_param_objs.values.each do |param|
		 if params[:book][:params][param.name.to_sym].present?
		     param.value = params[:book][:params][param.name.to_sym]
		     param.save!
		 end
	      end
	  end
	  
	  # remove any current series links
	  @book_series.book_series_joins.each do |join|
	     join.destroy
	  end

	  if !@book_series.update_attributes(params[:book_series], :as=>@role)
	      puts @book_series.errors.inspect
	      success = false
	  end 
	  @book_series.save!
          # create joins, linking books to the series
          goodreads = Roxiware::Goodreads::Book.new(:goodreads_user=>@goodreads_user)
          params[:book_series][:books].each do |book_order, series_book|
	     if series_book[:book_id].present?
	         book = Roxiware::Book.find(series_book[:book_id])
             elsif series_book[:goodreads_id].present?
                 book_join = Roxiware::GoodreadsIdJoin.where(:goodreads_id=>series_book[:goodreads_id]).first
                 if(book_join.present?)
                     book = book_join.grent
                 end
                 if book.blank?
		    goodreads_book = goodreads.get_book(series_book[:goodreads_id])
		    book = Roxiware::Book.where(:seo_index=>goodreads_book[:title].to_seo).first
		    if(book.blank?)
			book = Roxiware::Book.new
			book.from_goodreads_book(goodreads_book)
			book.init_sales_links
			book.save!
	            end
                 end
	     end
	     if book.present?
                 Roxiware::BookSeriesJoin.create({:book=>book, :book_series=>@book_series, :series_order=>book_order}, :as=>@role)
             end
          end
       rescue Exception => e
           print "FAILURE Creating or Updating Series: #{e.message}\n"
	   puts e.backtrace.join("\n")
	   success = false
           raise ActiveRecord::Rollback
       end
    end
    if (success) 
        run_layout_setup
    end
    success
  end

  def remove_book
    @book_series = Roxiware::BookSeries.find(params[:book_series_id])
    raise ActiveRecord::RecordNotFound if @book_series.nil?
    authorize! :update, @book_series
    @book_series.book_series_joins.where(:book_id=>params[:book_id]).first.destroy
    run_layout_setup
    respond_to do |format|
      format.html { redirect_to books_url }
      format.json { head :no_content }
    end
  end

  # DELETE /books/series/1
  # DELETE /books/series/1.json
  def destroy
    @book_series = Roxiware::BookSeries.find(params[:id])
    raise ActiveRecord::RecordNotFound if @book_series.nil?
    authorize! :destroy, @book_series
    @book_series.destroy
    run_layout_setup
    respond_to do |format|
      format.html { redirect_to books_url }
      format.json { head :no_content }
    end
  end
end
