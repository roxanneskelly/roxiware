class CreateNewsItems < ActiveRecord::Migration
  def change
    create_table :news_items do |t|
      t.string :seo_index
      t.datetime :post_date, :null=>false
      t.string :headline, :null=>false
      t.text :content, :null=>false
      t.timestamps
    end
    add_index(:news_items, [:seo_index], :unique=>true)
  end
end
