class RenameControllerToApplication < ActiveRecord::Migration
  def up
      rename_column :page_layouts, :controller, :application
      Roxiware::Layout::PageLayout.all.each do |page_layout|
          page_layout.application = page_layout.application.split("/")[1]
	  page_layout.save!
      end
  end

  def down
      Roxiware::Layout::PageLayout.all.each do |page_layout|
          if(page_layout.application == "blog") 
	      page_layout.application = page_layout.appliction+"/post"
	  end
          page_layout.application = "roxiware#{page_layout.application}"
	  page_layout.save!
      end
      rename_column :page_layouts, :controller, :application
  end
end
