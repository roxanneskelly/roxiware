class AddPageIdentifierAndTypeToPage < ActiveRecord::Migration
  def change
    rename_column :pages, :page_type, :page_identifier
    add_column :pages, :page_type, :string, :default=>"content"
  end
end
