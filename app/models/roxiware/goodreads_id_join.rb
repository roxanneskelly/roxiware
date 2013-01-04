class Roxiware::GoodreadsIdJoin < ActiveRecord::Base
  include Roxiware::BaseModel
  self.table_name= "goodreads_id_joins"
  
  belongs_to :grent, :polymorphic=>true

  edit_attr_accessible :goodreads_id, :as=>[:super, :admin, :user, nil]
  ajax_attr_accessible :goodreads_id, :as=>[:super, :admin, :user, :guest, nil]
end
