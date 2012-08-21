class CreateLayoutSections < ActiveRecord::Migration
  def change
    create_table :layout_sections do |t|
      t.references :page_layout
      t.string :name, :null=>false
      t.integer :page_layout_id, :null=>false
      t.text :style
      t.timestamps
    end
    add_index :layout_sections, :name
  end
end
