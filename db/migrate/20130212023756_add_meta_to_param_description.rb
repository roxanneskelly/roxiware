class AddMetaToParamDescription < ActiveRecord::Migration
  def change
    add_column :param_descriptions, :meta, :string
  end
end
