require 'builder'
require 'xml'
require 'fileutils'
require "open-uri"
require 'tempfile'

ENV['RAILS_ENV'] ||= "development"

namespace :wordpress do
    desc "export"
    task :export =>:environment do |t|
        xml = ::Builder::XmlMarkup.new(:indent=>2, :target=>$stdout)
        xml.instruct! :xml, :version => "1.0"
        xml.settings do |xml_params|
            params.each do |param|
                param.export(xml_params, true)
            end
        end
    end
end

namespace :settings do
    desc "list"
    task :list =>:environment do |t|
        Roxiware::Param::Param.settings.each do |param|
            print "#{param.name} : #{param.value}\n#{param.description.description}\n"
        end
    end

    desc "Update settings (not overwriting)"

    task :update, [:settings_file]=>:environment do |t, args|
        Rake::Task["param_descriptions:import"].invoke()
        settings_file = args[:settings_file] || "#{Roxiware::Engine.root}/lib/defaults/author_settings.xml"
        puts "Loading settings from #{settings_file}"
        parser = XML::Parser.file(settings_file)
        doc_obj = parser.parse
        param_nodes = doc_obj.find("/settings/param")
        param_nodes.each do |param_node|
            old_param = Roxiware::Param::Param.where(:name=>param_node["name"], :param_class=>param_node["class"]).first
            if(old_param.blank?)
                param = Roxiware::Param::Param.new
                param.import(param_node, true)
                param.save!
            end
        end
    end

    desc "Import settings"
    task :import, [:settings_file]=>:environment do |t, args|
        Rake::Task["param_descriptions:import"].invoke()
        settings_file = args[:settings_file] || "#{Roxiware::Engine.root}/lib/defaults/author_settings.xml"
        puts "Loading settings from #{settings_file}"
        parser = XML::Parser.file(settings_file)
        doc_obj = parser.parse
        param_nodes = doc_obj.find("/settings/param")
        param_nodes.each do |param_node|
            param = Roxiware::Param::Param.new
            Roxiware::Param::Param.where(:name=>param_node["name"], :param_class=>param_node["class"]).each{ |old_param| old_param.destroy }
            param.import(param_node, true)
            param.save!
        end
    end

    desc "Export a setting"
    task :export, [:setting]=>:environment do |t,args|
        xml = ::Builder::XmlMarkup.new(:indent=>2, :target=>$stdout)
        xml.instruct! :xml, :version => "1.0"
        if args[:setting].present? 
            params = Roxiware::Param::Param.where(:param_object_type=>nil, :name=>args[:setting])
        else
            params = Roxiware::Param::Param.where(:param_object_type=>nil)
        end
        xml.settings do |xml_params|
            params.each do |param|
                param.export(xml_params, true)
            end
        end
    end
end

namespace :widgets do
    desc "list"
    task :list =>:environment do |t|
        Roxiware::Layout::Widget.all.each do |widget|
            print "#{widget.name} : #{widget.guid}\n#{widget.description}\n"
        end
    end

    desc "Import widgets"
    task :import, [:widget_file]=>:environment do |t, args|
        Rake::Task["param_descriptions:import"].invoke()
        if args[:widget_file].present?
            files = [args[:widget_file]]
        else
            files = Dir.glob("#{Roxiware::Engine.root}/lib/widgets/*.xml")
            files = files + Dir.glob(Rails.root.join("lib","widgets","*.xml"))
        end
        files.each do |filename|
            puts "IMPORTING WIDGET FILE #{filename}"
            parser = XML::Parser.file(filename)
            doc_obj = parser.parse
            widget_nodes = doc_obj.find("/widgets/widget")
            widget_nodes.each do |widget_node|
                widget = Roxiware::Layout::Widget.new
                old_widget = Roxiware::Layout::Widget.where(:guid=>widget_node["guid"]).first
                old_widget.destroy if old_widget.present?
                widget.import(widget_node)
                widget.save!
            end
        end
    end

    desc "Export a widget"
    task :export, [:widget]=>:environment do |t,args|
        xml = ::Builder::XmlMarkup.new(:indent=>2, :target=>$stdout)
        xml.instruct! :xml, :version => "1.0"
        if args[:widget].present?
            widgets = Roxiware::Layout::Widget.where(:guid=>args[:widget])
        else
            widgets = Roxiware::Layout::Widget.all
        end
        xml.widgets do |xml_widgets|
            widgets.each do |widget|
                widget.export(xml_widgets)
            end
        end
    end
end

namespace :layout do
    desc "Import a layout"
    task :import, [:layout_file]=>:environment do |t, args|
        Rake::Task["param_descriptions:import"].invoke()
        if(args[:layout_file].blank?)
            puts "Must specify a layout file"
            return
        end
        parser = XML::Parser.file(args[:layout_file])
        doc_obj = parser.parse
        layout_nodes = doc_obj.find("/layout")
        layout_nodes.each do |layout_node|
            layout = Roxiware::Layout::Layout.new
            old_layout = Roxiware::Layout::Layout.where(:guid=>layout_node["guid"]).first
            old_layout.destroy if old_layout.present?
            layout.import(layout_node)
            layout.save!
        end
    end
end

namespace :templates do
    desc "style"
    task :style, [:controller,:action]=>:environment do |t, args|
        print Roxiware::Layout::Layout.all.first.get_styles(args[:controller],args[:action])
    end

    desc "list"
    task :list =>:environment do |t|
        Roxiware::Layout::Layout.all.each do |layout|
            print "#{layout.name}\n#{layout.description}\n\n"
        end
    end

    desc "Get thumbnail for layout running on server"
    task :get_thumbnail, [:hostname]=>:environment do |t,args|
        template = Roxiware::Param::Param.application_param_val("system","current_template")
        scheme = Roxiware::Param::Param.application_param_val("system","layout_scheme")
        hostname = args[:hostname] || Roxiware::Param::Param.application_param_val("system","hostname")
        template_obj = Roxiware::Layout::Layout.find_by_guid(template)

        dir_path = File.expand_path(File.join("~", "template_images", template_obj.name.to_seo)).to_s
        FileUtils.mkdir_p(dir_path)
        url = "http://#{hostname}/"
        filename = File.join(dir_path, "thumbnail.jpg")
        File.open(filename, "w") do |f|
            f.write open("http://api.snapito.com/web/5c643ee605beba218dceb460b6ee909333e48825/300x400/?url=#{url}&freshness=1").read
        end
        template_obj.set_param("chooser_image", "http://cdn.roxiware.com/templates/#{template_obj.name.to_seo}/thumbnail.jpg", "0B092D47-0161-42C8-AEEC-6D7AA361CF1D", "template")
        sh "ssh roxiwarevps@ps77127.dreamhost.com 'mkdir -p ~/cdn.roxiware.com/templates/#{template_obj.name.to_seo}'"
        sh "scp #{dir_path}/thumbnail.jpg roxiwarevps@ps77127.dreamhost.com:~/cdn.roxiware.com/templates/#{template_obj.name.to_seo}"
    end


    desc "Get images for layout running on server"
    task :get_images, [:hostname,:thumbnail_scheme]=>:environment do |t,args|
        template = Roxiware::Param::Param.application_param_val("system","current_template")
        thumbnail_scheme = args[:thumbnail_scheme] || Roxiware::Param::Param.application_param_val("system","layout_scheme")
        hostname = args[:hostname] || AppConfig.preview_server

        template_obj = Roxiware::Layout::Layout.find_by_guid(template)

        pages = {:home=>"/",:posts=>"/blog",:calendar=>"/events",:books=>"/books",:biography=>"/biography"}
        dir_path = File.expand_path(File.join("~", "template_images", template_obj.name.to_seo)).to_s
        FileUtils.mkdir_p(dir_path)

        # for each scheme, query the front page of the server
        template_obj.get_param("schemes").h.each do |scheme_id, scheme_data|
            url = "http://#{hostname}/?preview=#{template},#{scheme_id}"
            filename = File.join(dir_path, scheme_data.h['name'].to_s.to_seo+".jpg")
            puts "retrieving #{filename}"
            File.open(filename, "w") do |f|
                puts "http://api.snapito.com/web/5c643ee605beba218dceb460b6ee909333e48825/300x200/?freshness=1&url=#{url}"
                f.write open("http://api.snapito.com/web/5c643ee605beba218dceb460b6ee909333e48825/300x200/?freshness=1&url=#{url}").read
            end
            template_obj.get_param("schemes").h[scheme_id].set_param("thumbnail_image", "http://cdn.roxiware.com/templates/#{template_obj.name.to_seo}/#{scheme_data.h['name'].to_s.to_seo}.jpg", "0B092D47-0161-42C8-AEEC-6D7AA361CF1D", "scheme");
        end
        url = "http://#{hostname}/?preview=#{template},#{thumbnail_scheme}"
        filename = File.join(dir_path, "chooser_image.jpg")
        puts "retrieving #{filename}"
        File.open(filename, "w") do |f|
            f.write open("http://api.snapito.com/web/5c643ee605beba218dceb460b6ee909333e48825/400x250/?url=#{url}&freshness=1").read
        end
        template_obj.set_param("chooser_image", "http://cdn.roxiware.com/templates/#{template_obj.name.to_seo}/chooser_image.jpg", "0B092D47-0161-42C8-AEEC-6D7AA361CF1D", "scheme");


        sh "ssh roxiwarevps@ps77127.dreamhost.com 'mkdir -p ~/cdn.roxiware.com/templates/#{template_obj.name.to_seo}'"
        sh "scp #{dir_path}/* roxiwarevps@ps77127.dreamhost.com:~/cdn.roxiware.com/templates/#{template_obj.name.to_seo}"
        template_obj.save!
    end

    desc "Import templates"
    task :import, [:layout_file]=>:environment do |t, args|
        Rake::Task["param_descriptions:import"].invoke()
        if args[:layout_file].present?
            files = [args[:layout_file]]
        else
            files = Dir.glob("#{Roxiware::Engine.root}/lib/templates/*.xml")
            files = files + Dir.glob(Rails.root.join("lib","templates","*.xml"))
        end
        files.each do |filename|
            puts "Loading layout from #{filename}"
            parser = XML::Parser.file(filename)
            doc_obj = parser.parse
            layout_nodes = doc_obj.find("/layouts/layout")
            layout_nodes.each do |layout_node|
                layout = Roxiware::Layout::Layout.new
                old_layout = Roxiware::Layout::Layout.where(:guid=>layout_node["guid"]).first
                old_layout.destroy if old_layout.present?
                layout.import(layout_node)
                layout.save!
            end
            layout_nodes = doc_obj.find("/layout")
            layout_nodes.each do |layout_node|
                layout = Roxiware::Layout::Layout.new
                old_layout = Roxiware::Layout::Layout.where(:guid=>layout_node["guid"]).first
                old_layout.destroy if old_layout.present?
                layout.import(layout_node)
                layout.save!
            end
        end
    end

    desc "Export templates"
    task :export, [:layout]=>:environment do |t,args|
        xml = ::Builder::XmlMarkup.new(:indent=>2, :target=>$stdout)
        xml.instruct! :xml, :version => "1.0"
        if(args[:layout].present?)
            layouts = Roxiware::Layout::Layout.where(:name=>args[:layout])
        else
            layouts = Roxiware::Layout::Layout.all
        end
        xml.layouts do |xml_layouts|
            layouts.each do |layout|
                layout.export(xml_layouts)
            end
        end
    end
end



namespace :param_descriptions do
    desc "Import a list of param descriptions"
    task :import, [:description_file]=>:environment do |t, args|
        if args[:description_file].present?
            files = [args[:description_file]]
        else
            files = Dir.glob("#{Roxiware::Engine.root}/lib/defaults/param_descriptions.xml")
            files = files + Dir.glob(Rails.root.join("lib","defaults","param_descriptions.xml"))
        end

        files.each do |filename|
            parser = XML::Parser.file(filename)
            doc_obj = parser.parse
            description_nodes = doc_obj.find("/param_descriptions/param_description")
            description_nodes.each do |description_node|
                description = Roxiware::Param::ParamDescription.new
                old_description = Roxiware::Param::ParamDescription.where(:guid=>description_node["guid"]).first
                old_description.destroy if old_description.present?
                description.import(description_node)
                description.save!
            end
        end
    end

    task :export, [:description_file]=>:environment do |t,args|
        xml = ::Builder::XmlMarkup.new(:indent=>2, :target=>$stdout)
        xml.instruct! :xml, :version => "1.0"
        descriptions = Roxiware::Param::ParamDescription.all
        xml.param_descriptions do |xml_description|
            descriptions.each do |description|
                description.export(xml_description)
            end
        end
    end
end


namespace :roxiware do
    desc "Package a roxiware image"
    task :package, [:packagename]=>:environment do |t,args|
        packagename ||= Rails.root.basename(".git") + "." + `git log -1 --format="%H"`[0..7]
        #system "tar -czf #{targetdir}.tar.gz #{targetdir}"
    end

    desc "Backup a roxiware instance"
    task :backup do |t|
        root_path = Rails.root.join("backups").to_s
        backup_base_name = DateTime.now.strftime("%Y%m%d%H%M%S%L")
        path = Pathname.new(root_path).join(backup_base_name)
        Dir.mkdir Pathname.new(root_path) if !(File.directory? Pathname.new(root_path))
        Dir.mkdir path

        db_path = Rails.root.join("db", ENV['RAILS_ENV']+".sqlite3")
        puts "Backing up to #{path}.tgz"
        FileUtils.cp Rails.root.join("db", ENV['RAILS_ENV']+".sqlite3"), path.join("db.sqlite3")

        instance_config = Rails.root.join("config","instance_config.yml")
        if File.file?(instance_config)
            FileUtils.cp instance_config, path.join("instance_config.yml")
        end
        Dir.mkdir path.join("uploads")
        if ENV['RAILS_ENV'] == "development"
            files = Dir.glob(Rails.root.join("app", "assets", "images", "uploads", "*"))
        else
            files = Dir.glob(Rails.root.join("public", "assets", "uploads", "*"))
        end
        FileUtils.cp_r files, path.join("uploads")
        sh "tar -C #{path} -czf #{path}.tgz ."
        FileUtils.rm_r(path)
        if AppConfig.root_backup_location.present?
            backup_server, backup_path = AppConfig.root_backup_location.split(":")
            if backup_path.nil?
                backup_path = backup_server
                sh "cp #{path}.tgz  #{backup_path}"
            else
                backup_path += "/#{Rails.root.split().last}"
                sh "ssh #{backup_server} '[ -d #{backup_path} ] || mkdir -p #{backup_path}'"
                sh "scp #{path}.tgz '#{backup_server}:#{backup_path}'"
            end
        end
    end

    desc "Restore a roxiware instance"
    task :restore, [:backup_file]=>:environment do |t,args|
        backup_file = args[:backup_file] || Dir.glob(Rails.root.join("backups", "*.tgz")).sort_by{|p| p.to_s}.last

        puts "Restoring from #{backup_file}"

        if ENV['RAILS_ENV'] == "development"
            asset_dir = Rails.root.join("app", "assets", "images")
        else
            asset_dir = Rails.root.join("public", "assets")
        end

        FileUtils.rm_r(asset_dir.join("uploads.old")) if File.directory? asset_dir.join("uploads.old")
        FileUtils.mv asset_dir.join("uploads"), asset_dir.join("uploads.old") if File.directory? asset_dir.join("uploads")
        FileUtils.mkdir asset_dir.join("uploads")
        sh "tar -C #{asset_dir} -xzf #{backup_file} --include='uploads/*'"
        puts "done"

        sh "tar -C #{Rails.root.join("db")} -xzf #{backup_file} --include db.sqlite3"
        FileUtils.mv Rails.root.join("db", "db.sqlite3"), Rails.root.join("db", "#{ENV['RAILS_ENV']}.sqlite3")


        sh "tar -C #{Rails.root.join("config")} -xzf #{backup_file} --include instance_config.yml"
        FileUtils.rm_r(asset_dir.join("uploads.old"))
    end

    desc "Base Initialize a roxiware instance"
    task :base_init, [:instance_type]=>:environment do |t,args|
        Rake::Task["db:create"].invoke
        Rake::Task["db:migrate"].invoke
        Rake::Task["db:seed"].invoke
        Rake::Task["param_descriptions:import"].invoke
        Rake::Task["widgets:import"].invoke
        Rake::Task["templates:import"].invoke
        if ENV['RAILS_ENV'] == "production"
            Rake::Task["assets:precompile"].invoke
            Dir.mkdir Rails.root.join("tmp") if !(File.directory? Rails.root.join("tmp"))
        end
    end

    desc "Initialize a cold deployed package"
    task :package_init, [:instance_type]=>:environment do |t,args|
        instance_type = args[:instance_type] || :basic
        settings_file = Rails.root.join("lib","defaults","#{instance_type}_settings.xml")
        if !File.file?(settings_file)
            settings_file = "#{Roxiware::Engine.root}/lib/defaults/#{instance_type}_settings.xml"
        end
        Rake::Task["settings:import"].invoke(settings_file)
        File.open(Rails.root.join("config", "instance_config.yml"), "w") do |f|
            f.write("roxiware_params:\n")
            f.write("    application: #{instance_type}\n")
        end
        Dir.mkdir Rails.root.join("tmp") if !(File.directory? Rails.root.join("tmp"))
        FileUtils.touch Rails.root.join("tmp","restart.txt")
    end

    desc "Initialize a roxiware instance"
    task :init, [:instance_type]=>:environment do |t,args|
        instance_type = args[:instance_type] || :basic
        Rake::Task["roxiware:backup"].invoke
        if ENV['RAILS_ENV'] == "development"
            FileUtils.rm_rf(Dir.glob(Rails.root.join("app", "assets", "images", "uploads", "*")))
        else
            FileUtils.rm_rf(Dir.glob(Rails.root.join("public", "assets", "uploads", "*")))
        end
        FileUtils.rm_rf(Dir.glob(Rails.root.join("logs", "*")))
        Rake::Task["db:drop"].invoke
        Rake::Task["roxiware:base_init"].invoke
        Rake::Task["roxiware:package_init"].invoke(instance_type)
    end

    desc "update a roxiware instance"
    task :update, [:instance_type]=>:environment do |t,args|
        instance_type = args[:instance_type] || :author
        settings_file = Rails.root.join("lib","defaults","#{instance_type}_settings.xml").to_s
        puts "Checking #{settings_file}"
        if !File.file?(settings_file)
            settings_file = "#{Roxiware::Engine.root}/lib/defaults/#{instance_type}_settings.xml"
        end
        Rake::Task["roxiware:backup"].invoke
        Rake::Task["db:migrate"].invoke
        Rake::Task["db:seed"].invoke
        Rake::Task["param_descriptions:import"].invoke
        Rake::Task["widgets:import"].invoke
        Rake::Task["templates:import"].invoke
        Rake::Task["settings:update"].invoke(settings_file)
        File.open(Rails.root.join("config", "instance_config.yml").to_s, "w") do |f|
            f.write("roxiware_params:\n")
            f.write("    application: #{instance_type}\n")
        end
        if ENV['RAILS_ENV'] == "production"
            Rake::Task["assets:precompile"].invoke
            FileUtils.touch Rails.root.join("tmp","restart.txt")
        end
    end

    desc "restart a roxiware instance"
    task :restart, [:instance_type]=>:environment do |t,args|
        FileUtils.touch Rails.root.join("tmp","restart.txt")
    end

    desc "reset a roxiware instance back to it's install state"
    task :reset, [:instance_type]=>:environment do |t,args|
        #File.unlink(Rails.root.join("db","#{ENV['RAILS_ENV']}.sqlite3"))
        #File.delete(Rails.root.join("db","development.sqlite3"))
        #sleep(20);
        Rake::Task["db:purge"].invoke
        Rake::Task["db:migrate"].invoke
        #Rake::Task["roxiware:init"].invoke(args[:instance_type])
    end

    desc "Init Webserver Config"
    task :config_web, [:host,:slot,:domain_name,:aliases,:package_type]=>:environment do |t,args|
        domain_name=args[:domain_name]
        slot=args[:slot]
        aliases=args[:aliases]
        package_type=args[:package_type]
        conf_file_data = <<-EOF
server {
    listen #{args[:host]}:80;
    listen #{args[:host]}:443 ssl;
    listen 127.0.0.1:80;
    listen 127.0.0.1:443 ssl;
    server_name #{slot} #{domain_name} #{args[:aliases]};

    access_log /home/roxiwarevps/sites/#{slot}/log/access.log combined;
    error_log /home/roxiwarevps/sites/#{slot}/log/error.log error;

    root /home/roxiwarevps/sites/#{slot}/public;

    index index.html index.htm;

    autoindex off;

    passenger_enabled on;
    passenger_base_uri /;
    passenger_min_instances 1;

    # Disallow access to config / VCS data
    location ~* /\.(ht|svn|git) {
        deny all;
    }
    # Statistics
    location /stats/ {
        alias /home/roxiwarevps/sites/#{slot}/stats;
        auth_basic "Statistics Area";
        auth_basic_user_file /home/roxiwarevps/sites/#{slot}/stats/.htpasswd;
    }
}
EOF
        if %w(premium_blog author slot).include?(package_type)
            conf_file_data << "passenger_pre_start http://#{slot}/;"
        end
        if(domain_name.present?)
            domain_components = domain_name.split(".")
            redirect_domain = "www."+domain_name
            if(domain_components[0] == "www")
                domain_components.shift
                redirect_domain = domain_components.join(".")
            end
            redirect_file_data = <<-EOF
server {
    listen #{args[:host]}:80;
    listen #{args[:host]}:443 ssl;
    server_name #{redirect_domain};
    return 301 $scheme://#{domain_name}$request_uri;
}
EOF
        end
        File.open(Rails.root.join("config","nginx.conf"), "w") do |f|
            f.write(redirect_file_data)
            f.write(conf_file_data)
        end
    end
end
