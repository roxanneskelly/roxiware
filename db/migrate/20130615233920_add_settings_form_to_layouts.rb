class AddSettingsFormToLayouts < ActiveRecord::Migration
  def change
    add_column :layouts, :settings_form, :text
  end
end
