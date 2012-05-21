class AddPersonToUser < ActiveRecord::Migration
  def change
    add_column :users, :person_id, :integer
    add_column :people, :user_id, :integer
    add_column :people, :show_in_directory, :boolean, :default=>false
    add_index :users, :person_id
  end
end
