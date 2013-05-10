require 'builder'
require 'xml'
require 'fileutils'

ENV['RAILS_ENV'] ||= "development"

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
	    old_param = Roxiware::Param::Param.where(:name=>param_node["name"], :param_class=>param_node["class"]).first
	    old_param.destroy if old_param.present?
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
    desc "Backup a roxiware instance"
    task :backup do |t|
        root_path = ENV['SITE_BACKUP_DIR']  || Rails.root.join("backups").to_s
	backup_dirname = DateTime.now.strftime("%Y%m%d%H%M%S%L")
	path = Pathname.new(root_path).join(DateTime.now.strftime("%Y%m%d%H%M%S%L"))
        Dir.mkdir Pathname.new(root_path)if !(File.directory? Pathname.new(root_path))
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
    end

    desc "Restore a roxiware instance"
    task :restore do |t|
        backup_file = ENV['BACKUP_FILE']
	if backup_file.blank?
            root_path = ENV['SITE_BACKUP_DIR']  || Rails.root.join("backups").to_s
            backup_file = Dir.glob(Pathname.new("#{root_path}").join("*.tgz")).sort_by{|p| p.to_s}.last
	end
	puts "Restoring from #{backup_file}"

	if ENV['RAILS_ENV'] == "development"
	    asset_dir = Rails.root.join("app", "assets", "images")
	else
	    asset_dir = Rails.root.join("public", "assets")
	end

	FileUtils.rm_r(asset_dir.join("uploads.old")) if File.directory? asset_dir.join("uploads.old")
	FileUtils.mv asset_dir.join("uploads"), asset_dir.join("uploads.old") if File.directory? asset_dir.join("uploads")
	FileUtils.mkdir asset_dir.join("uploads")
	sh "tar -C #{asset_dir} -xzf #{backup_file} --include uploads/* "
	puts "done"

	sh "tar -C #{Rails.root.join("db")} -xzf #{backup_file} --include db.sqlite3"
        FileUtils.mv Rails.root.join("db", "db.sqlite3"), Rails.root.join("db", "#{ENV['RAILS_ENV']}.sqlite3")


	sh "tar -C #{Rails.root.join("config")} -xzf #{backup_file} --include instance_config.yml"
	FileUtils.rm_r(asset_dir.join("uploads.old"))

    end

    desc "Initialize a roxiware instance"
    task :init, [:instance_type]=>:environment do |t,args|
       instance_type = args[:instance_type] || :author
       settings_file = Rails.root.join("lib","defaults","#{instance_type}_settings.xml")
       if !File.file?(settings_file)
           settings_file = "#{Roxiware::Engine.root}/lib/defaults/#{instance_type}_settings.xml"
       end
       Rake::Task["roxiware:backup"].invoke
       Rake::Task["db:drop"].invoke
       Rake::Task["db:create"].invoke
       Rake::Task["db:migrate"].invoke
       Rake::Task["db:seed"].invoke
       Rake::Task["param_descriptions:import"].invoke
       Rake::Task["widgets:import"].invoke
       Rake::Task["templates:import"].invoke
       Rake::Task["settings:import"].invoke(settings_file)
       File.open(Rails.root.join("config", "instance_config.yml"), "w") do |f|
           f.write("roxiware_params:\n")
           f.write("    application: #{instance_type}\n")
       end
       if ENV['RAILS_ENV'] == "production"
           Rake::Task["assets:precompile"].invoke
           Dir.mkdir Rails.root.join("tmp") if !(File.directory? Rails.root.join("tmp"))
           FileUtils.touch Rails.root.join("tmp","restart.txt")
       end
    end

    desc "update a roxiware instance"
    task :update, [:instance_type]=>:environment do |t,args|
       instance_type = args[:instance_type] || :author
       settings_file = Rails.root.join("lib","defaults","#{instance_type}_settings.xml")
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
       File.open(Rails.root.join("config", "instance_config.yml"), "w") do |f|
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
    task :config_web, [:host, :domain_name,:aliases]=>:environment do |t,args|
        domain_name=args[:domain_name]
	aliases=args[:aliases]
        conf_file_data = <<-EOF
server {
    listen #{args[:host]}:80;
    server_name #{args[:domain_name]} #{args[:aliases]};

    access_log /home/roxiwarevps/sites/#{domain_name}/log/access.log combined;
    error_log /home/roxiwarevps/sites/#{domain_name}/log/error.log error;

    root /home/roxiwarevps/sites/#{domain_name}/public;

    index index.html index.htm index.php index.php5;

    # No mirrors - using strict redirects
    if ($http_host != setup901.roxiware.com) {
        rewrite ^(.*)$ http://#{domain_name}$1 permanent;
    }

    autoindex on;

    passenger_enabled on;
    passenger_base_uri /;

    # Disallow access to config / VCS data
    location ~* /\.(ht|svn|git) {
        deny all;
    }
    # Statistics
    location /stats/ {
        alias /home/roxiwarevps/sites/#{domain_name}/stats;
        auth_basic "Statistics Area";
        auth_basic_user_file /home/roxiwarevps/sites/#{domain_name}/stats/.htpasswd;
    }

    location /doc/analog/ {
        alias /usr/share/analog/;
    }

    # PHPMyAdmin
    rewrite ^/dh_phpmyadmin/([^/]*)/(.*)$ /dh_phpmyadmin/$2;

    location /dh_phpmyadmin/ {
        alias /dh/web/phpmyadmin/;
    }

    location ~ /dh_phpmyadmin/(.+)\.php {
        alias /dh/web/phpmyadmin/;
        fastcgi_param SERVER_PORT 80;
        fastcgi_split_path_info ^(.+\.php)(/.*)$;
        include /dh/nginx/etc/fastcgi_params;
        set $relpath "index.php";
        if ($uri ~ ^/dh_phpmyadmin/(.+)$) {
            set $relpath $1;
        }
        fastcgi_param SCRIPT_FILENAME /dh/web/phpmyadmin/$relpath;
        fastcgi_pass unix:/home/roxiwarevps/.php.sock;
    }

    # PHP
    location ~* \.(php|php5|php4)($|/) {
        fastcgi_param SERVER_PORT 80;
        fastcgi_split_path_info ^(.+\.(?:php|php5|php4))(/.*)$;
        if (!-e $document_root$fastcgi_script_name) {
            return 404;
        }
        include /dh/nginx/etc/fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_pass unix:/home/roxiwarevps/.php.sock;
        #pragma php_launch roxiwarevps
    }

}
EOF
        File.open(Rails.root.join("config","nginx.conf"), "w") do |f|
            f.write(conf_file_data)
        end
    end
end
