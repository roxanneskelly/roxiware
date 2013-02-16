class AddLayoutChooser < ActiveRecord::Migration
  def self.up
      add_column :layouts, :setup, :text


      Roxiware::Terms::TermTaxonomy.find_or_create_by_name({:description=>"Layout Category", :name=>Roxiware::Terms::TermTaxonomy::LAYOUT_CATEGORY_NAME}, :as=>"")
  end


  def self.down
      remove_column :layouts, :setup, :text

     category = Roxiware::Terms::TermTaxonomy.where(:name=>Roxiware::Terms::TermTaxonomy::LAYOUT_CATEGORY_NAME).first
     category.destroy if category.present?
  end
end
