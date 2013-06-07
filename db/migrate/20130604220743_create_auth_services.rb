class CreateAuthServices < ActiveRecord::Migration
  def change
    create_table :auth_services do |t|
      t.integer :user_id
      t.string :provider
      t.string :uid

      t.timestamps
    end
    add_index(:auth_services, [:provider, :uid])
  end
end
