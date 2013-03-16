
class Roxiware::SetupController < ApplicationController

   application_name = 'setup'
   
   layout "roxiware/layouts/setup_layout"

   before_filter do
      @role = "guest"
      @role = current_user.role unless current_user.nil?
      @setup_step ||= "welcome"
      authenticate_user! if @setup_step != "welcome"
      @setup_type = nil if @setup_step == "welcome"
   end


   # GET /setup
   def show
      template = [@setup_type, @setup_step].compact.join("_")
      setup_function = "_show_"+[@setup_type, @setup_step].compact.join("_")
      send("_show_"+[@setup_type, @setup_step].compact.join("_")) if respond_to?(setup_function, true)
      respond_to do |format|
        format.html {render :template=>"roxiware/setup/#{template}"}
      end
   end


   # PUT /setup
   def update
      send("_"+[@setup_type, @setup_step].compact.join("_"))

      @setup_type = Roxiware::Param::Param.application_param_val('setup', 'setup_type') 
      @setup_step = Roxiware::Param::Param.application_param_val('setup', 'setup_step') || 'welcome'

      @setup_type = nil if(@setup_type.blank?)

      respond_to do |format|
         format.html {redirect_to "/"}
         format.xml { render :xml=>{}}
      end
   end

   def import
      result = {}
      if(params[:type] == "author")
         goodreads = Roxiware::Goodreads::Book.new(:goodreads_user=>@goodreads_user)
	  if params[:search].present?
	     search_params = {}
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
			 search_params[:name]=match[1].sub(/_/, " ")
		     end
		  elsif site_uri.host == "www.goodreads.com"
		     if(match = site_uri.path.match(/\/book\/show\/(\d+)[\.-]([\w_-]+)/))
			 search_params[:goodreads_book_id] = match[1]
			 search_params[:title]=match[2]
		     elsif(match = site_uri.path.match(/\/author\/(\d+)[\.-]([\w_-]+)/))
			  search_params[:goodreads_id] = match[1]
			  search_params[:name]=match[2]
		     end
		  end
	       rescue
	       end
	    end
	    search_params[:name] = params[:search] 
	    search_params[:title] = params[:search]
	    result = goodreads.search_author(search_params)
	  end
      end
      respond_to do |format|
         format.json { render :json => result }
      end
   end

   def _set_setup_step(setup_step)
      Roxiware::Param::Param.set_application_param("setup", "setup_step", "317C7D1C-7316-4B00-9E1F-931E2867B436", setup_step)
   end

   # The user has selected a username, password, and so on.  Now we must create
   # the user entry in the database, and log in.
   def _welcome
      if(params[:setup_step] == "welcome")
         @user = Roxiware::User.where(:username=>params[:username]).first
      else
         @user = Roxiware::User.new
      end
      @user = Roxiware::User.new
      if @user.update_attributes(params, :as=>"")
           @user.role = "admin"
           Roxiware::Param::Param.set_application_param("setup", "setup_type", "5C5D2A03-F90E-4F81-AF44-8C182EB338FB", "author")
           _set_setup_step("name")
	   sign_in(:user, @user)
      else
          error_result = @user.errors.collect{|error| error[1]}.join("<br/>")
	  @user.destroy
	  flash[:error] = error_result
      end
   end

   def _author_name
      if ((params[:setup_action] == "back_button") || (params[:setup_step] == "welcome"))
           Roxiware::Param::Param.set_application_param("setup", "setup_type", "5C5D2A03-F90E-4F81-AF44-8C182EB338FB", nil)
	  if (current_user.present?)
	     user = current_user
	     sign_out
	     user.destroy
	  end
          _set_setup_step("welcome")
      else
          current_user.build_person({:first_name=>params[:first_name], :last_name=>params[:last_name], :middle_name=>params[:middle_name], :role=>"", :bio=>"", :email=>current_user.email}, :as=>"")
	  if(!current_user.save)
              error_result = current_user.errors.collect{|error| error[1]}.join("<br/>")
              flash[:error] = error_result
	  else
	     if params[:setup_action] == "skip_import"
                _set_setup_step("edit_biography")
             elsif params[:setup_action] == "import"
	         _set_setup_step("import_biography")
             end
          end
      end
   end

   def _author_import_biography
      if params[:setup_action] == "back_button"
	  if (current_user.present?)
	     current_user.person.delete
	  end
          _set_setup_step("name")
      elsif params[:setup_action] == "skip_import"
          current_user.person.update_attributes({:role=>"", :bio=>"", :email=>current_user.email, :thumbnail_url=>"", :image_url=>"", :large_image_url=>""}, :as=>"")
          _set_setup_step("edit_biography")
      elsif params[:goodreads_id].present?
          current_user.person.goodreads_id=params[:goodreads_id]
          goodreads = Roxiware::Goodreads::Book.new(:goodreads_user=>@goodreads_user)
	  author = goodreads.search_author({:goodreads_id=>params[:goodreads_id]}).first;
	  if(author.present?)
	      current_user.person.bio = author[:about]
	      current_user.person.thumbnail_url = author[:thumbnail_url]
	      current_user.person.image_url = author[:image_url]
	      current_user.person.large_image_url = author[:large_image_url]
	      # import image here
	      current_user.person.save!
	  end
          _set_setup_step("edit_biography")
      end
   end

   def _author_edit_biography
      @books = []
      if params[:setup_action] == "back_button"
          if current_user.person.goodreads_id_join.present?
	      _set_setup_step("import_biography")
	      current_user.person.goodreads_id_join.destroy
	  else
	     _set_setup_step("name")
	  end
      elsif params[:setup_action] == "save"
        current_user.person.show_in_directory = true;
        if(!current_user.person.update_attributes(params[:person], :as=>@role))
          error_result flash[:error] = @user.errors.collect{|error| error[1]}.join("<br/>")
	else
	   Roxiware::Param::Param.set_application_param("people", "default_biography", "B908FDB5-A0B5-48AC-8BAE-48741485CC06", current_user.person.id)
	   Roxiware::Param::Param.set_application_param("system", "webmaster_email", "9041D4FC-D97F-44F0-BFF2-FC2B4D3F6270", current_user.person.email)
	   Roxiware::Param::Param.set_application_param("system", "site_copyright_first_year", "7D815EDA-93DA-411B-9B09-91BA774D6CE2", Time.now.strftime("%Y"))
	   Roxiware::Param::Param.set_application_param("system", "site_copyright", "4454EFC0-EC3C-4C9D-8EF5-6F848E3B33D7", current_user.person.full_name)
	   Roxiware::Param::Param.set_application_param("system", "title", "0B8CFD7C-39AA-4E61-A4F2-9E7212EF9415", current_user.person.full_name+", Author")
	   Roxiware::Param::Param.set_application_param("system", "meta_description", "F0E1D8A9-33B9-4605-B10F-831D2BB3D423", current_user.person.full_name)
	   Roxiware::Param::Param.set_application_param("system", "meta_keywords", "1843B11F-EBA1-4B9A-A01F-F98A3E458FA8", current_user.person.full_name+", Author")
	   Roxiware::Param::Param.set_application_param("blog", "blog_editor_email", "89139210-E699-4D47-A656-B2F860D2015B", current_user.person.email)
	   Roxiware::Param::Param.set_application_param("blog", "blog_title", "3D102055-8C9B-4838-90F7-2B3C7DB23A1D", current_user.person.full_name+", Author")
	   _set_setup_step("social_networks")
	end
      end
    end

   def _author_social_networks
      @books = []
      if params[:setup_action] == "back_button"
	_set_setup_step("edit_biography")
      elsif params[:setup_action] == "save"
        if(!current_user.person.update_attributes(params[:person], :as=>@role))
          error_result flash[:error] = @user.errors.collect{|error| error[1]}.join("<br/>")
	else
	   if current_user.person.goodreads_id
	       seo_books = {}
	       _get_goodreads_author_books.each do |book|
		   seo_books[book.title.to_seo] = book if (seo_books[book.title.to_seo].blank? || book.description.present?)
	       end
	       @books = seo_books.values
	   end
	   _set_setup_step("manage_books")
	end
      end
    end

    def _show_author_manage_books
       @books = Roxiware::Book.all
       if @books.blank? && current_user.person.goodreads_id
	   seo_books = {}
	   _get_goodreads_author_books.each do |book|
	       seo_books[book.title.to_seo] = book if (seo_books[book.title.to_seo].blank? || book.description.present?)
	   end
	   @books = seo_books.values
       end
    end


    def _author_manage_books
        @books = []
	if params[:setup_action] == "back_button"
          destroy_books = Roxiware::Book.all
	  destroy_books.each do |book|
	     book.destroy
	  end
	  _set_setup_step("social_networks")
	elsif params[:setup_action] == "save"
            Roxiware::Book.all.each do |book|
	       book.destroy
            end
	    @books = []
	    books = params[:books][:book] if params[:books]
	    books ||= []
	    if books.class != Array
	       books = [books]
            end
	    books.each do |book|
	       new_book = Roxiware::Book.new(book, :as=>@role)
	       new_book.init_sales_links
	       new_book.save!
	       @books << new_book
	    end
	    if @books.present?
	       _set_setup_step("series")
	    else
	       _set_setup_step("choose_template")
	    end
        end
    end

    def _author_series
      if params[:setup_action] == "back_button"
	  _set_setup_step("manage_books")
      else
          if params[:setup_action] == "skip_series"
	       _set_setup_step("choose_template")
	  elsif params[:setup_action] == "import"
	       _set_setup_step("manage_series")
	  end
      end
    end

    def _show_author_manage_series
       @books = Roxiware::Book.all
       # filter series by books
       @books_by_goodreads_id = Hash[@books.select{|book| book.goodreads_id.present?}.collect{|book| [book.goodreads_id, book]}]

       @series = []
       if current_user.person.goodreads_id
	    goodreads_series = _get_goodreads_author_series
	    goodreads_series.each do |series|
	       series[:book_ids] = []
	       series[:books].each do |book|
		  book[:book_id] = @books_by_goodreads_id[book[:id].to_i].id if @books_by_goodreads_id[book[:id].to_i].present?
		  series[:book_ids] << book[:book_id] if book[:book_id]
	       end

	       if series[:book_ids].present?
		  @series << series
	       end
	    end
        end
    end


    def _author_manage_series
      if params[:setup_action] == "back_button"
	  _set_setup_step("series")
      elsif params[:setup_action] == "save"
          series_list = params[:series][:series]
	  if(series_list.class != Array)
	      series_list = [series_list]
          end
          series_list.each do |series|
             book_series = Roxiware::BookSeries.new
	     ActiveRecord::Base.transaction do
	        begin
		  if !book_series.update_attributes(series, :as=>@role)
		      success = false
		  end 
		  book_series.save!
		  # create joins, linking books to the series
		  order = 1
		  books = series[:books][:book]
		  books.sort! {|x, y| x[:order].to_i <=> y[:order].to_i}
		  books.each do |book|
                     book_obj = Roxiware::Book.find(book[:id].to_i)
                     if(book_obj.present?) 
                        Roxiware::BookSeriesJoin.create({:book=>book_obj, :book_series=>book_series, :series_order=>order}, :as=>@role)
	                order = order + 1
                     end
		  end
	       rescue Exception => e
		   print "FAILURE Creating Series: #{e.message}\n"
		   puts e.backtrace.join(",")
		   success = false
		   raise ActiveRecord::Rollback
	       end
	     end
          end
          _set_setup_step("choose_template")
      end
    end

    def _show_author_choose_template
        @layouts = []
        category_ids = Set.new([])
        Roxiware::Layout::Layout.all.each do |layout|
  	   next if cannot? :read, layout
	   schemes = []
	   layout.get_param("schemes").h.each do |scheme_id, scheme|
              large_image_urls = scheme.h["large_images"].a.each.collect{|image| image.conv_value}
	      schemes << {:id=>scheme_id,
                        :name=>scheme.h["name"].to_s,
                        :thumbnail_image=>scheme.h["thumbnail_image"].to_s,
			:large_images=>large_image_urls}
	   end
	    
	   categories=layout.terms(:term_taxonomy_id=>Roxiware::Terms::TermTaxonomy.taxonomy_id(Roxiware::Terms::TermTaxonomy::LAYOUT_CATEGORY_NAME)).collect{|category| category.id}
	   category_ids.merge(categories)
	   layout_data = {:name=>layout.name,
                          :guid=>layout.guid,
                          :thumbnail_url=>layout.get_param("chooser_image").to_s,
			  :description=>layout.description,
	                  :categories=>categories,
                          :schemes=>schemes}
	   if(@default_template.blank? && categories.blank?) 
	       @default_template = layout.guid
	       @default_scheme=schemes[0][:id]
           end
	   @layouts << layout_data
	end
        @categories = Roxiware::Terms::Term.where(:id=>category_ids.to_a)
	
    end

    def _author_choose_template
	if params[:setup_action] == "back_button"
            @books = Roxiware::Book.all
	    if @books.present?
	        _set_setup_step("manage_series")
            else
                _set_setup_step("manage_books")
	    end
	elsif params[:setup_action] == "save_template"
            # we've chosen the template, so set it, do the setup, and go to completion page
	    refresh_layout
	    Roxiware::Param::Param.refresh_application_params
            Roxiware::Param::Param.set_application_param("system", "current_template", "B8A73EF2-9C65-4022-ABD3-2D4063827108", params[:template_guid])
            Roxiware::Param::Param.set_application_param("system", "layout_scheme", "99FA5423-147C-4929-A432-268BDED6DE44", params[:template_scheme])
	    _set_setup_step("complete")
        end
    end

    def _author_complete
      if params[:button] == "back"
           Roxiware::Param::Param.set_application_param("system", "current_template", "B8A73EF2-9C65-4022-ABD3-2D4063827108", "")
           Roxiware::Param::Param.set_application_param("system", "layout_scheme", "99FA5423-147C-4929-A432-268BDED6DE44", "")
	  _set_setup_step("choose_template")
      end
    end
    
    def _get_goodreads_author_books
       goodreads = Roxiware::Goodreads::Book.new(:goodreads_user=>@goodreads_user)
       begin
           goodreads_books = goodreads.get_author_books(current_user.person.goodreads_id)
       rescue Exception => e
	  flash[:error] = e.message
	  goodreads_books = []
       end
       books = []
       goodreads_books.each do |goodreads_book|
          book = Roxiware::Book.new
          book.from_goodreads_book(goodreads_book)
	  books << book
       end
       books
    end

    def _get_goodreads_author_series
       goodreads = Roxiware::Goodreads::Book.new(:goodreads_user=>@goodreads_user)
       goodreads.search_series({:goodreads_author_id=>current_user.person.goodreads_id})
    end
end
