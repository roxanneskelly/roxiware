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
   end

    # GET /setup
    def show
        verifier = ActiveSupport::MessageVerifier.new(AppConfig.host_setup_verify_key)
        verified_result = verifier.verify(params[:key]) if params[:key].present?
        #verified_result = nil if verified_result.present? && (verified_result.shift < Time.now)
        verified_result.shift
        if(verified_result.nil? && params[:key].present?)
            redirect_to "http://www.scribaroo.com/"
            return;
        end
        @verified_params = ActiveSupport::JSON.decode(verified_result.first)

        Roxiware::Param::Param.set_application_param("system", "hosting_package", "EE71224A-52E0-42D6-A7C9-97FFB7972329", "basic_author") if @setup_step == "welcome"
        Roxiware::Param::Param.set_application_param("system", "hostname", "9311CEF8-86CE-44C0-B3DD-126B718A26C2", request.host) if @setup_step == "welcome"

        @setup_type ||= @verified_params['site_type']
        if @verified_params.present?
            @person = current_user.person if current_user.present?
            if @setup_step == "welcome"
                ActiveRecord::Base.transaction do
                    begin
                        #we're just starting so initialize some paramters and create our user
                        _set_setup_step("edit_biography")
                        @setup_step = "edit_biography"
                        # generate a random password as for this user we'll do an oauth to www.scribaroo.com
                        password = password = Devise.friendly_token.first(20)
                        @user = Roxiware::User.new({:username=>@verified_params['username'],
                                                          :email=>@verified_params['email'],
                                                          :password=>password,
                                                          :password_confirmation=>password,
                                                          :role=>"admin"}, :as=>"")
                        Roxiware::Param::Param.set_application_param("setup", "setup_type", "5C5D2A03-F90E-4F81-AF44-8C182EB338FB", @setup_type)
                        Roxiware::Param::Param.set_application_param("system", "hosting_package", "EE71224A-52E0-42D6-A7C9-97FFB7972329", @verified_params['site_type'])
                        Roxiware::Param::Param.set_application_param("system", "hostname", "9311CEF8-86CE-44C0-B3DD-126B718A26C2", @verified_params['hostname'])
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
                            Roxiware::Param::Param.set_application_param("system", "subtitle", "0B8CFD7C-39AA-4E61-A4F2-9E7212EF9415", "Author")
                        when 'basic_blog'
                            Roxiware::Param::Param.set_application_param("books", "enable_books", "F9373A7F-EFCE-4FFF-9055-B7BFA6D61B63", false)
                            Roxiware::Param::Param.set_application_param("system", "subtitle", "0B8CFD7C-39AA-4E61-A4F2-9E7212EF9415", "Blogger")
                        when 'premium_blog'
                            Roxiware::Param::Param.set_application_param("books", "enable_books", "F9373A7F-EFCE-4FFF-9055-B7BFA6D61B63", false)
                            Roxiware::Param::Param.set_application_param("system", "google_ad_client", "289108C9-5CFA-4599-BC54-B4E3593E4FC5", "")
                            Roxiware::Param::Param.set_application_param("system", "subtitle", "0B8CFD7C-39AA-4E61-A4F2-9E7212EF9415", "Blogger")
                        else
                            Roxiware::Param::Param.set_application_param("books", "enable_books", "F9373A7F-EFCE-4FFF-9055-B7BFA6D61B63", false)
                        end

                        @person = @user.build_person({:first_name=>@verified_params['first_name'],
                                                :last_name=>@verified_params['last_name'],
                                                :email=>@verified_params['email'],
                                                :role=>"", :bio=>""}, :as=>"")
                        @user.auth_services.build({:provider=>"roxiware", :uid=>"username"}, :as=>"")
                        social_networks = @person.set_param("social_networks", {}, "4EB6BB84-276A-4074-8FEA-E49FABC22D83", "local")
                        (@verified_params['social_networks'] || {}).each do |provider, uid|
                            @user.auth_services.build({ :provider=>provider, :uid=>uid }, :as=>"")
                            social_network = social_networks.set_param(provider, {}, "5CC121A6-AB23-49B4-BB14-0E03119F00E6", "local")
                            social_network.set_param("uid", uid, "FB528C00-8510-4876-BD82-EF694FEAC06D", "local")
                        end
                        @person.save!
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
                @person = current_user.person if current_user.present?
            end
        elsif @setup_step != "welcome"
            authenticate_user!
        end
        template = [@setup_type, @setup_step].compact.join("_")
        setup_function = "_show_"+[@setup_type, @setup_step].compact.join("_")
        send("_show_"+[@setup_type, @setup_step].compact.join("_")) if respond_to?(setup_function, true)
        respond_to do |format|
            format.html {render}
        end
    end


    # PUT /setup
    def update
        result = send("_#{@setup_step}") || {}
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

    # import author information
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
                    author[:bio] = (Sanitize.clean(author[:about][0..300], Roxiware::Sanitizer::BASIC_SANITIZER)+"...")
                end
            end
        end
        respond_to do |format|
            format.json { render :json => result }
        end
    end

    # get books for an author
    def books
        @books = Roxiware::Book.order("publish_date ASC")
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
            @books = seo_books.values.sort{|x, y| x.publish_date <=> y.publish_date}.collect{|book| book.ajax_attrs(@role)}
        end
        respond_to do |format|
            format.json { render :json => @books }
        end
    end

    def _set_setup_step(setup_step)
        result = {}
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


    def _edit_biography
        result = nil
        ActiveRecord::Base.transaction do
            begin
                current_user.person.show_in_directory = true;
                current_user.person.assign_attributes(params[:person], :as=>@role)
                if(!current_user.person.save)
                    result = report_error(current_user.person)
                else
                    Roxiware::Param::Param.set_application_param("system", "title", "0B8CFD7C-39AA-4E61-A4F2-9E7212EF9415", params[:person][:full_name])
                    Roxiware::Param::Param.set_application_param("people", "default_biography", "B908FDB5-A0B5-48AC-8BAE-48741485CC06", current_user.person.id)
                    Roxiware::Param::Param.set_application_param("system", "site_copyright_first_year", "7D815EDA-93DA-411B-9B09-91BA774D6CE2", Time.now.strftime("%Y"))
                    social_networks = current_user.person.set_param("social_networks", {}, "4EB6BB84-276A-4074-8FEA-E49FABC22D83", "local")
                    (params[:social_networks] || []).each do |name, value|
                        social_network = social_networks.set_param(name, {}, "5CC121A6-AB23-49B4-BB14-0E03119F00E6", "local")
                        social_network.set_param("uid", value, "FB528C00-8510-4876-BD82-EF694FEAC06D", "local")
                    end
                    result = _set_setup_step("site_setup")
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

    def _site_setup
        result = nil
        ActiveRecord::Base.transaction do
            begin
                Roxiware::Param::Param.set_application_param("system", "title", "0B8CFD7C-39AA-4E61-A4F2-9E7212EF9415", params[:settings][:title])
                Roxiware::Param::Param.set_application_param("system", "subtitle", "0B8CFD7C-39AA-4E61-A4F2-9E7212EF9415", params[:settings][:subtitle])
                Roxiware::Param::Param.set_application_param("system", "meta_description", "F0E1D8A9-33B9-4605-B10F-831D2BB3D423", params[:settings][:meta_description])
                Roxiware::Param::Param.set_application_param("system", "meta_keywords", "1843B11F-EBA1-4B9A-A01F-F98A3E458FA8", params[:settings][:meta_keywords])
                if(@setup_type=="author")
                    result = _set_setup_step("manage_books")
                else
                    result = _set_setup_step("first_blog_post")
                end
            rescue Exception => e
                result ||= {}
                result[:error] ||= []
                result[:error] << ["exception", e.message]
                puts "FAILURE editing setting system settings: #{e.message}"
                puts e.backtrace.join("\n")
                raise ActiveRecord::Rollback
            end
        end
        result
    end



    def _manage_books
        result = nil
        ActiveRecord::Base.transaction do
            begin
                @books = []
                # delete all existing books and series so we don't accidentally overwrite them
                Roxiware::GoodreadsIdJoin.delete_all(:grent_type=>"Roxiware::Book")
                Roxiware::GoodreadsIdJoin.delete_all(:grent_type=>"Roxiware::BookSeries")
                Roxiware::BookSeriesJoin.delete_all
                Roxiware::BookSeries.delete_all
                Roxiware::Book.delete_all
                books_doc = Nokogiri::XML(request.body)
                books = []
                result = {}
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
                    new_book.large_image = book_node.search('image').text
                    new_book.thumbnail = book_node.search('thumbnail').text
                    new_book.init_sales_links
                    new_book.save!
                    if(new_book.errors.present?)
                        result = report_error(new_book)
                        break
                    end
                    books << new_book
                end
                result = _set_setup_step("first_blog_post") unless result[:errors].present?
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

    def _first_blog_post
        result = {}
        ActiveRecord::Base.transaction do
            begin
                @post = Roxiware::Blog::Post.new
                @post.update_attributes(params[:first_post].merge({ :person_id=>current_user.person.id,
                                                                    :post_date=>DateTime.now.utc,
                                                                    :blog_class=>"blog",
                                                                    :comment_permissions=>"default",
                                                                    :post_status=>"publish"}), :as=>"")
                @post.save!
                if @post.errors.blank?
                    site_api = Admin::Site.new(Roxiware::Param::Param.application_param_val('system', 'hostname'))
                    site_api.status = "up"
                    result = _set_setup_step("complete")
                else
                    result = report_error(@post)
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


    def _get_goodreads_author_books
        goodreads = Roxiware::Goodreads::Book.new(:goodreads_user=>@goodreads_user)
        begin
            goodreads_books = goodreads.get_author_books(current_user.person.goodreads_id)
        rescue Exception => e
            flash[:error] = e.message
            goodreads_books = []
        end
        books = {}
        goodreads_books.each do |goodreads_book|
            continue if goodreads_book[:title].blank?
            book = Roxiware::Book.new
            book.from_goodreads_book(goodreads_book)
            books[book.title.to_seo] ||= book
            books[book.title.to_seo] = book if (book.description.length > books[book.title.to_seo].description.length)
        end
        books.values.sort{ |a,b| a.publish_date <=> b.publish_date }
    end

    def _get_goodreads_author_series
        goodreads = Roxiware::Goodreads::Book.new(:goodreads_user=>@goodreads_user)
        goodreads.search_series({:goodreads_author_id=>current_user.person.goodreads_id})
    end
end
