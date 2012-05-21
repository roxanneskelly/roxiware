class CreateSecretPages < ActiveRecord::Migration
  def change
    create_table :secret_pages do |t|
      t.string :secret
      t.timestamps
    end
  end
end
