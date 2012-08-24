require 'builder'
require 'xml'

namespace :widget do
      desc "list"
      task :list =>:environment do |t|
         Roxiware::Layout::Widget.all.each do |widget|
	    print "#{widget.name} : #{widget.guid}\n#{widget.description}\n\n"
	 end
      end

      desc "Import widgets"
      task :import, [:widget_file]=>:environment do |t, args|
	 parser = XML::Parser.file(args[:widget_file])
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
	 parser = XML::Parser.file(args[:layout_file])
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

