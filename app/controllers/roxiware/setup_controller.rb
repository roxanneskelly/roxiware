require 'nokogiri'


class Roxiware::SetupController < ApplicationController
    application_name = 'setup'

   after_action do
       response.headers['X-Frame-Options'] = "ALLOW-FROM http://www.scribaroo.com/"
   end

   layout "roxiware/layouts/setup_layout"

    skip_before_filter :verify_authenticity_token, :if => :check_verify_key
    def check_verify_key
        params[:key].present?
    end

   before_filter do
      @role = "guest"
      @role = current_user.role unless current_user.nil?
      @setup_step ||= "welcome"
      @setup_type = nil if @setup_step == "welcome"

      verifier = ActiveSupport::MessageVerifier.new(AppConfig.host_setup_verify_key)
      verified_result = verifier.verify(params[:key]) if params[:key].present?
      verified_result = nil if verified_result.present? && (verified_result.shift < Time.now)
      if(verified_result.nil? && params[:key].present?)
          raise ActiveResource::UnauthorizedAccess
      end
      @verified_params = ActiveSupport::JSON.decode(verified_result.first)
   end

    # GET /setup
    def show
        Roxiware::Param::Param.set_application_param("system", "hosting_package", "EE71224A-52E0-42D6-A7C9-97FFB7972329", "basic_author") if @setup_step == "welcome"
        Roxiware::Param::Param.set_application_param("system", "hostname", "9311CEF8-86CE-44C0-B3DD-126B718A26C2", request.host) if @setup_step == "welcome"

        if @verified_params.present?
            puts "SETUP STEP #{@setup_step}"
            puts "VERIFIED #{@verified_params.inspect}"
            if @setup_step == "welcome"
                ActiveRecord::Base.transaction do
                    begin
                        #we're just starting so initialize some paramters and create our user
                        case @verified_params["site_type"]
                        when "author"
                            @setup_type = "author"
                            _set_setup_step("import_biography")
                        when "basic_blog"
                            @setup_type = "blog"
                            _set_setup_step("edit_biography")
                        when "premium_blog"
                            @setup_type = "blog"
                            _set_setup_step("edit_biography")
                        else
                            @setup_type = "custom"
                        end

                        # generate a random password as for this user we'll do an oauth to www.scribaroo.com
                        password = password = Devise.friendly_token.first(20)
                        @user = Roxiware::User.new({:username=>@verified_params['username'],
                                                          :email=>@verified_params['email'],
                                                          :password=>password,
                                                          :password_confirmation=>password,
                                                          :role=>"admin"}, :as=>"")
                        Roxiware::Param::Param.set_application_param("setup", "setup_type", "5C5D2A03-F90E-4F81-AF44-8C182EB338FB", @setup_type)
                        Roxiware::Param::Param.set_application_param("system", "hosting_package", "EE71224A-52E0-42D6-A7C9-97FFB7972329", @verified_params['site_type'])
                        Roxiware::Param::Param.set_application_param("sysntem", "hostname", "9311CEF8-86CE-44C0-B3DD-126B718A26C2", @verified_params['hostname'])
                        Roxiware::Param::Param.set_application_param("system", "current_template", "B8A73EF2-9C65-4022-ABD3-2D4063827108", @verified_params['template_guid'])
                        Roxiware::Param::Param.set_application_param("system", "layout_scheme", "99FA5423-147C-4929-A432-268BDED6DE44", @verified_params['scheme_guid'])
                        Roxiware::Param::Param.set_application_param("blog", "blog_editor_email", "89139210-E699-4D47-A656-B2F860D2015B", @verified_params['email']) if @verified_params['email'].present?
                        Roxiware::Param::Param.set_application_param("system", "webmaster_email", "9041D4FC-D97F-44F0-BFF2-FC2B4D3F6270", @verified_params['email']) if @verified_params['email'].present?


                        # set the features based on the site type
                        Roxiware::Param::Param.set_application_param("blog", "enable_blog", "DAAC4690-FF6A-480B-B157-D71CB4A085DA", true)
                        Roxiware::Param::Param.set_application_param("people", "enable_people", "D1DBD840-3D0A-4F3A-A45E-719B4DF67F66", true)
                        Roxiware::Param::Param.set_application_param("events", "enable_events", "48C77594-AA7C-4424-90F8-BCA2EFFF7546", true)
                        Roxiware::Param::Param.set_application_param("gallery", "enable_gallery", "98E7A520-2A28-4521-9AA7-33E3EDB104DA", true)
                        case @verified_params['site_type']
                        when 'author'
                            Roxiware::Param::Param.set_application_param("books", "enable_books", "F9373A7F-EFCE-4FFF-9055-B7BFA6D61B63", true)
                            Roxiware::Param::Param.set_application_param("system", "google_ad_client", "289108C9-5CFA-4599-BC54-B4E3593E4FC5", "")
                        when 'basic_blog'
                            Roxiware::Param::Param.set_application_param("books", "enable_books", "F9373A7F-EFCE-4FFF-9055-B7BFA6D61B63", false)
                        when 'premium_blog'
                            Roxiware::Param::Param.set_application_param("books", "enable_books", "F9373A7F-EFCE-4FFF-9055-B7BFA6D61B63", false)
                            Roxiware::Param::Param.set_application_param("system", "google_ad_client", "289108C9-5CFA-4599-BC54-B4E3593E4FC5", "")
                        else
                            Roxiware::Param::Param.set_application_param("books", "enable_books", "F9373A7F-EFCE-4FFF-9055-B7BFA6D61B63", false)
                        end

                        @user.build_person({:first_name=>@verified_params['first_name'],
                                                :last_name=>@verified_params['last_name'],
                                                :email=>@verified_params['email'],
                                                :role=>"", :bio=>""}, :as=>"")
                        @user.auth_services.build({:provider=>"roxiware", :uid=>"username"}, :as=>"")
                        (@verified_params['auth_ services'] || []).each do |auth_service|
                            @user.auth_services.build(auth_service, :as=>"")
                        end
                        @user.save!
                        sign_in(:user, @user)
                    rescue Exception=>e
                        Rails.logger.error(e.message)
                        Rails.logger.error(e.backtrace.join("\n"))
                        puts e.message
                        puts e.backtrace.join("\n")
                        raise e
                    end
                end
            else
                @user = Roxiware::User.where(:username=>@verified_params['username']).first
                raise Exception.new("user not found") if @user.nil?
                sign_in(:user, @user)
            end
        elsif @setup_step != "welcome"
            authenticate_user!
        end
        template = [@setup_type, @setup_step].compact.join("_")
        setup_function = "_show_"+[@setup_type, @setup_step].compact.join("_")
        send("_show_"+[@setup_type, @setup_step].compact.join("_")) if respond_to?(setup_function, true)
        respond_to do |format|
            format.html {render :template=>"roxiware/setup/#{template}"}
        end
    end


    # PUT /setup
    def update
        result = send("_"+[@setup_type, @setup_step].compact.join("_")) || {}
        @setup_type = Roxiware::Param::Param.application_param_val('setup', 'setup_type')
        @setup_step = Roxiware::Param::Param.application_param_val('setup', 'setup_step') || 'welcome'
        @setup_type = nil if(@setup_type.blank?)

        respond_to do |format|
            if (result.present?)
                format.html {redirect_to "/", :error=>result}
            else
                format.html {redirect_to "/"}
            end
            format.xml { render :partial=>"roxiware/shared/xml_error", :locals=>{:error_data=>result}}
            format.json { render :json=>result}
        end
    end

    # import books for an author/amazon link/goodreads link
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
                result.each do |author|
                    author[:bio] = Sanitize.clean(author[:about][0..300], Roxiware::Sanitizer::BASIC_SANITIZER)+"..."
                end
            end
        end
        respond_to do |format|
            format.json { render :json => result }
        end
    end

    def _set_setup_step(setup_step)
        begin
            Roxiware::Param::Param.set_application_param("setup", "setup_step", "317C7D1C-7316-4B00-9E1F-931E2867B436", setup_step)
            @setup_step = setup_step
        rescue Exception => e
            result = {:error=>[["exception", e.message]]}
            puts "FAILURE setting setup step: #{e.message}"
            puts e.backtrace.join("\n")
        end
        result
    end

    # The user has selected a username, password, and so on.  Now we must create
    # the user entry in the database, and log in.
    def _welcome
        result = nil
        ActiveRecord::Base.transaction do
            begin
                @user = Roxiware::User.new
                @user.assign_attributes(params, :as=>"")
                if @user.save
                    @user.role = "admin"
                    Roxiware::Param::Param.set_application_param("setup", "setup_type", "5C5D2A03-F90E-4F81-AF44-8C182EB338FB", "author")
                    result = _set_setup_step("name")
                    sign_in(:user, @user)
                else
                    result = report_error(@user)
                end
            rescue Exception => e
                result ||= {}
                result[:error] ||= []
                result[:error] << ["exception", e.message]
                puts "FAILURE creating account: #{e.message}"
                puts e.backtrace.join("\n")
                raise ActiveRecord::Rollback
            end
        end
        result
    end

    def _author_name
        result = nil
        ActiveRecord::Base.transaction do
            begin
                if ((params[:setup_action] == "back_button") || (params[:setup_step] == "welcome"))
                    Roxiware::Param::Param.set_application_param("setup", "setup_type", "5C5D2A03-F90E-4F81-AF44-8C182EB338FB", nil)
                    if (current_user.present?)
                        user = current_user
                        sign_out
                        user.destroy
                    end
                    result = _set_setup_step("welcome")
                else
                    current_user.build_person({:first_name=>params[:first_name],
                                                  :last_name=>params[:last_name],
                                                  :middle_name=>params[:middle_name],
                                                  :role=>"",
                                                  :bio=>"",
                                                  :email=>current_user.email}, :as=>"")
                    if(!current_user.save)
                        result = report_error(current_user)
                    else
                        if params[:setup_action] == "skip_import"
                            result = _set_setup_step("edit_biography")
                        elsif params[:setup_action] == "import"
                            result = _set_setup_step("import_biography")
                        end
                    end
                end
            rescue Exception => e
                result ||= {}
                result[:error] ||= []
                result[:error] << ["exception", e.message]
                puts "FAILURE setting author name: #{e.message}"
                puts e.backtrace.join("\n")
                raise ActiveRecord::Rollback
            end
        end
        result
    end

    def _author_import_biography
        result = nil
        ActiveRecord::Base.transaction do
            begin
                if params[:setup_action] == "back_button"
                    if (current_user.present?)
                        current_user.person.delete
                    end
                    result = _set_setup_step("name")
                elsif params[:setup_action] == "skip_import"
                    current_user.person.assign_attributes({:role=>"", :bio=>"", :email=>current_user.email, :thumbnail=>"", :image=>"", :large_image=>""}, :as=>"")
                    if current_user.person.save
                        result = _set_setup_step("edit_biography")
                    else
                        result = report_error(current_user.person)
                    end
                elsif params[:goodreads_id].present?
                    current_user.person.goodreads_id=params[:goodreads_id]
                    goodreads = Roxiware::Goodreads::Book.new(:goodreads_user=>@goodreads_user)
                    author = goodreads.search_author({:goodreads_id=>params[:goodreads_id]}).first;
                    if(author.present?)
                        current_user.person.bio = author[:about]
                        current_user.person.thumbnail = author[:thumbnail]
                        current_user.person.image = author[:image]
                        current_user.person.large_image = author[:large_image]
                        # import image here
                        current_user.person.save!
                    end
                    result = _set_setup_step("edit_biography")
                end
            rescue Exception => e
                result ||= {}
                result[:error] ||= []
                result[:error] << ["exception", e.message]
                puts "FAILURE importing author biography: #{e.message}"
                puts e.backtrace.join("\n")
                raise ActiveRecord::Rollback
            end
        end
        result
    end

    def _edit_biography
        result = nil
        ActiveRecord::Base.transaction do
            begin
                @books = []
                if params[:setup_action] == "back_button"
                    if current_user.person.goodreads_id_join.present?
                        result = _set_setup_step("import_biography")
                        current_user.person.goodreads_id_join.destroy
                    else
                        result = _set_setup_step("name")
                    end
                elsif params[:setup_action] == "save"
                    current_user.person.show_in_directory = true;
                    current_user.person.assign_attributes(params[:person], :as=>@role)
                    if(!current_user.person.save)
                        result = report_error(current_user.person)
                    else
                        Roxiware::Param::Param.set_application_param("people", "default_biography", "B908FDB5-A0B5-48AC-8BAE-48741485CC06", current_user.person.id)
                        Roxiware::Param::Param.set_application_param("system", "site_copyright_first_year", "7D815EDA-93DA-411B-9B09-91BA774D6CE2", Time.now.strftime("%Y"))
                        result = _set_setup_step("social_networks")
                    end
                end
            rescue Exception => e
                result ||= {}
                result[:error] ||= []
                result[:error] << ["exception", e.message]
                puts "FAILURE editing author biography: #{e.message}"
                puts e.backtrace.join("\n")
                raise ActiveRecord::Rollback
            end
        end
        result
    end

    def _author_edit_biography
        _edit_biography
    end

    def _blog_edit_biography
        _edit_biography
    end

    def _show_social_networks
        @person = current_user.person
    end

    def _show_author_social_networks
        _show_social_networks
    end

    def _show_blog_social_networks
        _show_social_networks
    end

    def _set_social_networks
        if(params[:person][:params].present? && params[:person][:params][:social_networks].present?)
            social_networks = current_user.person.set_param("social_networks", {}, "4EB6BB84-276A-4074-8FEA-E49FABC22D83", "local")
            params[:person][:params][:social_networks].each do |name, value|
                social_network = social_networks.set_param(name, {}, "5CC121A6-AB23-49B4-BB14-0E03119F00E6", "local")
                social_network.set_param("uid", value[:uid], "FB528C00-8510-4876-BD82-EF694FEAC06D", "local")
                if(current_user.present? && can?(:edit, current_user))
                    social_network.set_param("allow_login", value[:allow_login], "CCD842C8-F516-49DD-A8C3-FF32750124D2", "local")
                    if value[:allow_login]
                        current_user.auth_services.create({:provider=>name, :uid=>value[:uid]}, :as=>@role)
                    end
                end
            end
        end
    end

    def _author_social_networks
        result = nil
        ActiveRecord::Base.transaction do
            begin
                @books = []
                if params[:setup_action] == "back_button"
                    result = _set_setup_step("edit_biography")
                elsif params[:setup_action] == "save"
                    ActiveRecord::Base.transaction do
                        begin
                            _set_social_networks
                            result = _set_setup_step("manage_books")
                            # preload the list of books
                            _show_author_manage_books
                        rescue Exception => e
                            print e.message
                            puts e.backtrace.join("\n")
                            raise e
                        end
                    end
                end
            rescue Exception => e
                result ||= {}
                result[:error] ||= []
                result[:error] << ["exception", e.message]
                puts "FAILURE setting social networks: #{e.message}"
                puts e.backtrace.join("\n")
                raise ActiveRecord::Rollback
            end
        end
        result
    end


    def _blog_social_networks
        result = nil
        ActiveRecord::Base.transaction do
            begin
                if params[:setup_action] == "back_button"
                    result = _set_setup_step("edit_biography")
                elsif params[:setup_action] == "save"
                    ActiveRecord::Base.transaction do
                        begin
                            _set_social_networks
                            result = _set_setup_step("choose_template")
                            # preload the list of books
                            _show_blog_choose_template
                        rescue Exception => e
                            print e.message
                            puts e.backtrace.join("\n")
                            raise e
                        end
                    end
                end
            rescue Exception => e
                result ||= {}
                result[:error] ||= []
                result[:error] << ["exception", e.message]
                puts "FAILURE setting social networks: #{e.message}"
                puts e.backtrace.join("\n")
                raise ActiveRecord::Rollback
            end
        end
        result
    end

    def _show_author_manage_books
        @books = Roxiware::Book.order("publish_date DESC")
        if @books.blank? && current_user.person.goodreads_id
            seo_books = {}
            grid_books = []
            _get_goodreads_author_books.each do |book|
                next if grid_books.include?(book.goodreads_id)
                grid_books << book.goodreads_id
                seo_title = book.title.to_seo
                init_title = book.title
                title_add = 1
                while(seo_books[seo_title].present?)
                    book.title = "#{init_title} (#{title_add})"
                    seo_title = book.title.to_seo
                    title_add += 1
                end
                seo_books[book.title.to_seo] = book
                book.save!
            end
            @books = seo_books.values.sort{|x, y| y.publish_date <=> x.publish_date}
        end
    end


    def _author_manage_books
        result = nil
        ActiveRecord::Base.transaction do
            begin
                @books = []
                if params[:setup_action] == "back_button"
                    # back button, delete all existing series and go to social networks
                    Roxiware::GoodreadsIdJoin.delete_all(:grent_type=>"Roxiware::Book")
                    Roxiware::GoodreadsIdJoin.delete_all(:grent_type=>"Roxiware::BookSeries")
                    Roxiware::Book.delete_all
                    Roxiware::BookSeriesJoin.delete_all
                    Roxiware::BookSeries.delete_all
                    result = _set_setup_step("social_networks")

                elsif params[:setup_action] == "save"
                    # delete all existing series so we don't accidentally overwrite them
                    Roxiware::GoodreadsIdJoin.delete_all(:grent_type=>"Roxiware::Book")
                    Roxiware::GoodreadsIdJoin.delete_all(:grent_type=>"Roxiware::BookSeries")
                    Roxiware::BookSeriesJoin.delete_all
                    Roxiware::BookSeries.delete_all
                    Roxiware::Book.delete_all
                    books_doc = Nokogiri::XML(request.body)
                    books = []
                    book_nodes = books_doc.xpath("//books/book")
                    book_nodes.each do |book_node|
                        new_book = Roxiware::Book.new
                        new_book.goodreads_id=book_node["goodreads_id"]
                        new_book.isbn=book_node["isbn"]
                        new_book.isbn13=book_node["isbn13"]
                        begin
                            new_book.publish_date = Date.strptime(book_node['publish_date'], "%m/%d/%Y") if book_node["publish_date"]
                        rescue Exception=>e
                            # On date parse errors, just leave a blank date
                        end
                        new_book.description = book_node.search('description').children.find{|e| e.cdata?}.text
                        new_book.title = book_node.search('title').text
                        new_book.image = book_node.search('image').text
                        new_book.large_image = book_node.search('large_image').text
                        new_book.thumbnail = book_node.search('thumbnail').text
                        new_book.init_sales_links
                        new_book.save!
                        books << new_book
                    end
                    if books.present?
                        # ask the author if they want to set their books up in a series
                        result = _set_setup_step("series")
                    else
                        # no books, so just let them choose their template
                        result = _set_setup_step("choose_template")
                    end
                end
            rescue Exception => e
                result ||= {}
                result[:error] ||= []
                result[:error] << ["exception", e.message]
                puts "FAILURE managing author books: #{e.message}"
                puts e.backtrace.join("\n")
                raise ActiveRecord::Rollback
            end
        end
        result
    end

    def _author_series
        result = nil
        ActiveRecord::Base.transaction do
            begin
                if params[:setup_action] == "back_button"
                    result = _set_setup_step("manage_books")
                else
                    if params[:setup_action] == "skip_series"
                        result = _set_setup_step("choose_template")
                    elsif params[:setup_action] == "import"
                        result = _set_setup_step("manage_series")
                    end
                end
            rescue Exception => e
                result ||= {}
                result[:error] ||= []
                result[:error] << ["exception", e.message]
                puts "FAILURE asking author series: #{e.message}"
                puts e.backtrace.join("\n")
                raise ActiveRecord::Rollback
            end
        end
        result
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
                series_books = series[:books]
                series[:books] = []
                series_books.each do |book|
                    book[:book_id] = @books_by_goodreads_id[book[:id].to_i].id if @books_by_goodreads_id[book[:id].to_i].present?
                    series[:book_ids] << book[:book_id] if book[:book_id]
                    series[:books] << book if book[:book_id]
                end

                if series[:book_ids].present?
                    @series << series
                end
            end
        end
    end


    def _author_manage_series
        result = nil
        ActiveRecord::Base.transaction do
            begin
                if params[:setup_action] == "back_button"
                    # when we get a 'back' within the series UI, make sure we delete all series
                    Roxiware::GoodreadsIdJoin.delete_all(:grent_type=>"Roxiware::BookSeries")
                    Roxiware::BookSeriesJoin.delete_all
                    Roxiware::BookSeries.delete_all
                    result = _set_setup_step("series")
                elsif params[:setup_action] == "save"
                    # we're getting a save from the series UI.  Go ahead and delete any 
                    # series that are already there.
                    Roxiware::GoodreadsIdJoin.delete_all(:grent_type=>"Roxiware::BookSeries")
                    Roxiware::BookSeriesJoin.delete_all
                    Roxiware::BookSeries.delete_all
                    series_doc = Nokogiri::XML(request.body)
                    series_nodes = series_doc.xpath("//series/series")
                    series_nodes.each do |series_node|
                        new_series = Roxiware::BookSeries.new
                        new_series.goodreads_id=series_node["goodreads_id"]
                        new_series.title = series_node.search('title').text
                        new_series.description = series_node.search('description').children.find{|e| e.cdata?}.text
                        new_series.image = series_node.search('image').text
                        new_series.large_image = series_node.search('large_image').text
                        new_series.thumbnail = series_node.search('thumbnail').text
                        order = 1
                        new_series.save!
                        series_node.search('books/book').each do |book_node|
                            book_obj = Roxiware::Book.find(book_node["id"].to_i)
                            new_series.book_series_joins.create({:book=>book_obj, :series_order=>order}, :as=>@role)
                            order += 1
                        end
                        new_series.save!
                    end
                    result = _set_setup_step("choose_template")
                end
            rescue Exception => e
                result ||= {}
                result[:error] ||= []
                result[:error] << ["exception", e.message]
                puts "FAILURE managing author series: #{e.message}"
                puts e.backtrace.join("\n")
                raise ActiveRecord::Rollback
            end
        end
        result
    end

    def _show_choose_template
        @layouts = []
        category_ids = Set.new([])
        package_name = Roxiware::Param::Param.application_param_val("system", "hosting_package")
        package_term = Roxiware::Terms::Term.where(:term_taxonomy_id=>Roxiware::Terms::TermTaxonomy.taxonomy_id(Roxiware::Terms::TermTaxonomy::LAYOUT_PACKAGE_NAME), :name=>package_name).first
        Roxiware::Layout::Layout.joins(:term_relationships).where(:term_relationships=>{:term_id=>package_term.id}).each do |layout|
            next if cannot? :read, layout
            schemes = []
            if(layout.get_param("schemes").present?)
                layout.get_param("schemes").h.each do |scheme_id, scheme|
                    large_image_urls = []
                    large_image_urls = scheme.h["large_images"].a.each.collect{|image| {:thumbnail=>image.h["thumbnail"].to_s, :full=>image.h["full"].to_s}} if scheme.h["large_images"].present?
                    schemes << {:id=>scheme_id,
                        :name=>scheme.h["name"].to_s,
                        :thumbnail_image=>scheme.h["thumbnail_image"].to_s,
                        :large_images=>large_image_urls}
                end
            end

            category_ids.merge(layout.category_ids)
            schemes.sort!{|x,y| x[:name] <=> y[:name]}
            layout_data = {:name=>layout.name,
                :guid=>layout.guid,
                :thumbnail_url=>layout.get_param("chooser_image").to_s,
                :description=>layout.description,
                :categories=>layout.category_ids,
                :schemes=>schemes}
            @layouts << layout_data
            if(@default_template.blank?) 
                @default_template = layout.guid
                @default_scheme=schemes[0][:id]
            end
        end
        @layouts.sort!{|x,y| x[:name] <=> y[:name]}

        cat_tree_build = {}
        # grab the categories and sort them so lesser specific items will come before their contained categories
        Roxiware::Terms::Term.where(:id=>category_ids.to_a).sort{|x, y| x.name <=> y.name}.each do |category|
            # for the category, split off it's name and find the parent name
            parent = category.name.split("/").reverse
            parent.shift

            cat_tree_build[parent.reverse.join("/")] ||= []
            cat_tree_build[parent.reverse.join("/")] << category
        end
        dfs = lambda do |current|
            Hash[cat_tree_build[current].collect{|category| [category, dfs.call(category.name)]}] if cat_tree_build[current].present?
        end

       @categories = dfs.call("")
    end

    def _show_author_choose_template
        _show_choose_template
    end

    def _show_blog_choose_template
        _show_choose_template
    end

    def _author_choose_template
        result = nil
        ActiveRecord::Base.transaction do
            begin
                if params[:setup_action] == "back_button"
                    @books = Roxiware::Book.all
                    @series = Roxiware::BookSeries.all
                    if @series.present?
                        result = _set_setup_step("manage_series")
                    else
                        result = _set_setup_step("series")
                    end
                elsif params[:setup_action] == "install_template"
                    # we've chosen the template, so set it, do the setup, and go to completion page
                    Roxiware::Param::Param.refresh_application_params
                    Roxiware::Param::Param.set_application_param("system", "current_template", "B8A73EF2-9C65-4022-ABD3-2D4063827108", params[:template_guid])
                    Roxiware::Param::Param.set_application_param("system", "layout_scheme", "99FA5423-147C-4929-A432-268BDED6DE44", params[:template_scheme])
                    refresh_layout
                    @current_template = params[:template_guid]
                    @layout_scheme = params[:template_scheme]
                    load_layout
                    run_layout_setup
                    result = _set_setup_step("complete")

                    # generate initial blog post
                    _author_gen_initial_blog_post
                end
            rescue Exception => e
                result = {:error=>[["exception", e.message]]}
                puts "FAILURE picking setup template: #{e.message}"
                puts e.backtrace.join("\n")
                raise ActiveRecord::Rollback
            end
        end
        result
    end


    def _blog_choose_template
        result = nil
        ActiveRecord::Base.transaction do
            begin
                if params[:setup_action] == "back_button"
                    result = _set_setup_step("social_networks")
                elsif params[:setup_action] == "install_template"
                    # we've chosen the template, so set it, do the setup, and go to completion page
                    Roxiware::Param::Param.refresh_application_params
                    Roxiware::Param::Param.set_application_param("system", "current_template", "B8A73EF2-9C65-4022-ABD3-2D4063827108", params[:template_guid])
                    Roxiware::Param::Param.set_application_param("system", "layout_scheme", "99FA5423-147C-4929-A432-268BDED6DE44", params[:template_scheme])
                    refresh_layout
                    @current_template = params[:template_guid]
                    @layout_scheme = params[:template_scheme]
                    load_layout
                    run_layout_setup
                    result = _set_setup_step("complete")

                    # generate initial blog post
                    _blog_gen_initial_blog_post

                end
            rescue Exception => e
                result = {:error=>[["exception", e.message]]}
                puts "FAILURE picking setup template: #{e.message}"
                puts e.backtrace.join("\n")
                raise ActiveRecord::Rollback
            end
        end
        result
    end

    def _author_complete
        result = nil
        ActiveRecord::Base.transaction do
            begin
                if params[:button] == "back"
                    Roxiware::Param::Param.set_application_param("system", "current_template", "B8A73EF2-9C65-4022-ABD3-2D4063827108", "")
                    Roxiware::Param::Param.set_application_param("system", "layout_scheme", "99FA5423-147C-4929-A432-268BDED6DE44", "")
                    _set_setup_step("choose_template")
                else
                    session[:return_to] = "/"
                end

            rescue Exception => e
                result ||= {}
                result[:error] ||= []
                result[:error] << ["exception", e.message]
                puts "FAILURE completing: #{e.message}"
                puts e.backtrace.join("\n")
                raise ActiveRecord::Rollback
            end
        end
        result
    end

    def _author_complete
        _complete
    end

    def _blog_complete
        _complete
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

    def _author_gen_initial_blog_post
        latest_book = Roxiware::Book.where(:publish_date=>(DateTime.new()..DateTime.now())).order("publish_date DESC").limit(1).first
        if latest_book.present?
            book_post = <<EOF
<p>Welcome to my website!</p>
<p>Be sure to check out my <a href="/books">books</a>, and if you'd like to find out more about me, take a look at my <a href="/biography">biography</a>.</p>
<p>And definitely enjoy my latest</p></br>
<a href="#{book_path(latest_book.seo_index)}" style="font-size:2em">#{ latest_book.title}</a><p style="clear:both"><a href="#{book_path(latest_book.seo_index)}"><img src="#{latest_book.image}" style="float:left;"/></a>#{latest_book.description}<br></p>
<p><br/>
<br/>
- #{current_user.person.full_name}
</p>
EOF
            @post = Roxiware::Blog::Post.create({:person_id=>current_user.person.id,
                                                    :post_date=>DateTime.now.utc,
                                                    :blog_class=>(params[:blog_class] || "blog"),
                                                    :post_content=>book_post,
                                                    :post_title=>"Welcome!",
                                                    :comment_permissions=>"default",
                                                    :post_status=>"publish"}, :as=>"")
        else
            _blog_gen_initial_blog_post
        end
    end


    def _blog_gen_initial_blog_post
        blog_post = <<EOF
<p>You can find out a bit about me <a href="/biography">here</a>!</p>
- #{current_user.person.full_name}
</p>
EOF

        @post = Roxiware::Blog::Post.create({:person_id=>current_user.person.id,
                                                :post_date=>DateTime.now.utc,
                                                :blog_class=>(params[:blog_class] || "blog"),
                                                :post_content=>blog_post,
                                                :post_title=>"Welcome!",
                                                :comment_permissions=>"default",
                                                :post_status=>"publish"}, :as=>"")
    end
end
