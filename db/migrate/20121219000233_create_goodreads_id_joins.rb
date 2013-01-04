class CreateGoodreadsIdJoins < ActiveRecord::Migration
  def change
     create_table :goodreads_id_joins do |t|
       t.integer :goodreads_id
       t.references :grent, :polymorphic=>true
     end
     add_index :goodreads_id_joins, :goodreads_id, :unique=>true
     add_index(:goodreads_id_joins, [:grent_id, :grent_type], :unique => true)
  end
end
