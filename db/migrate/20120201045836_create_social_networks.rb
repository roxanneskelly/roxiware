class CreateSocialNetworks < ActiveRecord::Migration
  def change
    create_table :social_networks do |t|
      t.references   :person, :null=>false
      t.string :network_type, :null=>false
      t.string :network_link, :null=>false
      t.timestamps
    end
  end
end
