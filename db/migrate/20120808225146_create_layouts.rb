class CreateLayouts < ActiveRecord::Migration
  def change
    create_table :layouts do |t|
      t.string :name, :null=>false
      t.string :guid, :null=>false
      t.text   :description
      t.text   :style
      t.timestamps
    end
  end
end
