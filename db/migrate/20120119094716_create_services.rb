class CreateServices < ActiveRecord::Migration
  def change
    create_table :services do |t|
      t.string :service_class
      t.string :name
      t.string :seo_index
      t.text :summary
      t.text :description
      t.timestamps
    end
    add_index (:services, [:service_class, :seo_index], :unique=>true)
  end
end
