class CreatePageLayouts < ActiveRecord::Migration
  def change
    create_table :page_layouts do |t|
      t.references :layout
      t.text   :style
      t.string :render_layout
      t.string :controller
      t.string :action
      t.integer :layout_id, :null=>false
      t.timestamps
    end
  end
end
