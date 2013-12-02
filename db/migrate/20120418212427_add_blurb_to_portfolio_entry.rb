class AddBlurbToPortfolioEntry < ActiveRecord::Migration
  def change
    add_column :portfolio_entries, :blurb, :text, :null=>false, :default=>""
    add_index(:portfolio_entries, [:seo_index], :unique=>true)
  end
end
