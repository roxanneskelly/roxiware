class CreateParamDescriptions < ActiveRecord::Migration
  def change
    create_table :param_descriptions do |t|
      t.string :guid
      t.string :name
      t.text :description
      t.string :field_type
      t.string :permissions
      t.timestamps
    end
    add_index :param_descriptions, :guid
  end
end
