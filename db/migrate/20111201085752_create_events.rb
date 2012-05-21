class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.datetime :start, :null=>false
      t.integer :duration
      t.string :duration_units
      t.string :city
      t.string :state
      t.string :address
      t.string :location
      t.string :location_url
      t.text :description, :null=>false
      t.timestamps
    end
  end
end
