class CreatePortfolioEntries < ActiveRecord::Migration
  def change
    create_table :portfolio_entries do |t|
      t.string :name
      t.string :image_url
      t.string :thumbnail_url
      t.text :description
      t.string :service_class
      t.string :url
      t.string :seo_index
      t.timestamps
    end
  end
end
