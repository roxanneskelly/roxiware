class CreateWidgetInstances < ActiveRecord::Migration
  def change
    create_table :widget_instances do |t|
      t.references :layout_section
      t.string     :widget_guid
      t.integer    :section_order, :null=>false
      t.timestamps
    end
  end
end
