class AddTextValueToParams < ActiveRecord::Migration
  def change
    add_column :params, :textvalue, :text
  end
end
