class CreateWidgets < ActiveRecord::Migration
  def change
    create_table :widgets do |t|
      t.string :guid, :null=>false
      t.string :name, :null=>false
      t.float  :version, :default=>1.0
      t.string :description
      t.text   :preload
      t.text   :render_view
      t.text   :style
      t.timestamps
    end
  end
end
