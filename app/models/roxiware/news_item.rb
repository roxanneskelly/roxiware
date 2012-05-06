module Roxiware
  class NewsItem < ActiveRecord::Base

    set_table_name "news_items"
    validates_presence_of :headline
    validates_uniqueness_of :headline
    validates :headline, :length => {:minimum=>2}
    
    before_validation() do
       self.seo_index = self.headline.downcase.gsub(/[^a-z0-9]+/i, '-')
    end


    attr_accessible :headline, :content, :post_date, :as=>"user"
    attr_accessible :headline, :content, :post_date, :as=>"admin"


    def writeable_attribute_names(current_user)
       role = current_user.role unless current_user.nil?
       case role
       when "admin"
          [:headline, :content, :post_date, :seo_index]
       when "user"
          [:headline, :content, :post_date, :seo_index]
       else
          []
       end
    end

  end

end
