class CreateLayoutParams < ActiveRecord::Migration
  def change
    create_table :layout_params do |t|
      t.string :layout_type, :null=>false
      t.string :name, :null=>false
      t.string :value
      t.integer :layout_object_id
      t.string :layout_object_type
      t.timestamps
    end
  end
end
