class AddEditformToWidget < ActiveRecord::Migration
  def change
    add_column :widgets, :editform, :text
  end
end
