class CreateBookSeriesJoins < ActiveRecord::Migration
  def change
    create_table :book_series_joins do |t|
      t.integer :book_id
      t.integer :book_series_id
      t.integer :series_order
    end
    add_index(:book_series_joins, [:book_series_id, :book_id], :unique => true)
  end
end
