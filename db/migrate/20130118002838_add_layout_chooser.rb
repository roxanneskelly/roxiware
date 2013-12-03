class AddLayoutChooser < ActiveRecord::Migration
  def self.up
      add_column :layouts, :setup, :text
      Roxiware::Terms::TermTaxonomy.where(:name=>Roxiware::Terms::TermTaxonomy::LAYOUT_CATEGORY_NAME).first_or_create!({:description=>"Layout Category"})
  end


  def self.down
      remove_column :layouts, :setup, :text
     category = Roxiware::Terms::TermTaxonomy.where(:name=>Roxiware::Terms::TermTaxonomy::LAYOUT_CATEGORY_NAME).first
     category.destroy if category.present?
  end
end
