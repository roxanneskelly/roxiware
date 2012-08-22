class CreateParams < ActiveRecord::Migration
  def change
    create_table :params do |t|
      t.string  :param_class, :null=>false
      t.string  :name, :null=>false
      t.string  :value
      t.integer :param_object_id
      t.string  :param_object_type
      t.string  :description_guid
      t.timestamps
    end
  end
end
