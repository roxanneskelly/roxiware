class CreatePeople < ActiveRecord::Migration
  def change
    create_table :people do |t|
      t.string :seo_index
      t.string :first_name
      t.string :last_name
      t.string :role
      t.string :email
      t.string :image_url
      t.text   :bio
      t.timestamps
    end
    add_index (:people, :seo_index, :unique=>true)
  end
end
