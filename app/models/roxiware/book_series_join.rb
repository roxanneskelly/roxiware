class Roxiware::BookSeriesJoin < ActiveRecord::Base
  include Roxiware::BaseModel
  self.table_name= "book_series_joins"

  belongs_to :book
  belongs_to :book_series

  edit_attr_accessible :book_id, :series_order, :series_id, :book, :book_series, :as=>[:super, :admin, :user, nil]
  ajax_attr_accessible :book_id, :series_order, :series_id, :book, :book_series, :as=>[:super, :admin, :user, :guest, nil]

end
