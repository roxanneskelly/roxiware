class AddPublishDateToBooks < ActiveRecord::Migration
  def change
    add_column :books, :publish_date, :datetime
    add_index :books, :publish_date
  end
end
