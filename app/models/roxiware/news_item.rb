module Roxiware
  class NewsItem < ActiveRecord::Base
   include Roxiware::BaseModel

    self.table_name="news_items"
    validates_presence_of :headline
    validates_uniqueness_of :headline
    validates :headline, :length => {:minimum=>2}
    validates_presence_of :post_date

    edit_attr_accessible :headline, :content, :post_date, :as=>[:user, :admin, nil]
    ajax_attr_accessible :headline, :content, :post_date

    
    before_validation() do
       self.seo_index = self.headline.downcase.gsub(/[^a-z0-9]+/i, '-')
    end
  end
end
