require 'builder'
require 'xml'

namespace :settings do
      desc "list"
      task :list =>:environment do |t|
         Roxiware::Param::Param.settings.each do |param|
	    print "#{param.name} : #{param.value}\n#{param.description.description}\n"
	 end
      end

      desc "Import settings"
      task :import, [:settings_file]=>:environment do |t, args|
	 parser = XML::Parser.file(args[:settings_file] || "#{Roxiware::Engine.root}/config/settings")
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

namespace :widget do
      desc "list"
      task :list =>:environment do |t|
         Roxiware::Layout::Widget.all.each do |widget|
	    print "#{widget.name} : #{widget.guid}\n#{widget.description}\n"
	 end
      end

      desc "Import widgets"
      task :import, [:widget_file]=>:environment do |t, args|
	 parser = XML::Parser.file(args[:widget_file] || "#{Roxiware::Engine.root}/config/widgets")
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

      desc "Import a layout"
      task :import, [:layout_file]=>:environment do |t, args|
	 parser = XML::Parser.file(args[:layout_file] || "#{Roxiware::Engine.root}/config/layouts")
	 doc_obj = parser.parse
	 layout_nodes = doc_obj.find("/layouts/layout")
	 layout_nodes.each do |layout_node|
	    layout = Roxiware::Layout::Layout.new
	    old_layout = Roxiware::Layout::Layout.where(:guid=>layout_node["guid"]).first
	    old_layout.destroy if old_layout.present?
	    layout.import(layout_node)
	    layout.save!
	 end
      end

      desc "Export a layout"
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
	 parser = XML::Parser.file(args[:layout_file] || "#{Roxiware::Engine.root}/config/param_descriptions")
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

