class Roxiware::BookSeries < ActiveRecord::Base
  include Roxiware::BaseModel
  self.table_name= "book_series"
  has_many        :params, :class_name=>"Roxiware::Param::Param", :as=>:param_object, :autosave=>true, :dependent=>:destroy
  has_many        :book_series_joins, :dependent=>:destroy, :autosave=>true
  has_many        :books, :through=>:book_series_joins
  has_one         :goodreads_id_join, :as=>:grent, :autosave=>true, :dependent=>:destroy

  validates_presence_of :title


  edit_attr_accessible :seo_index, :goodreads_id, :description, :image_url, :large_image_url, :thumbnail_url, :title, :as=>[:super, :admin, :user, nil]
  ajax_attr_accessible :seo_index, :goodreads_id, :description, :image_url, :large_image_url, :thumbnail_url, :title, :as=>[:super, :admin, :user, :guest, nil]

  def goodreads_id
      self.goodreads_id_join.goodreads_id if self.goodreads_id_join.present?
  end

  def goodreads_id=(gr_id)
      if self.goodreads_id_join.blank?
         self.goodreads_id_join = Roxiware::GoodreadsIdJoin.new
      end
      self.goodreads_id_join.goodreads_id = gr_id
  end

  def get_param_objs
     if @param_objs.nil?
        @param_objs = {}
        params.each do |param|
           @param_objs[param.name.to_sym] =  param
        end
     end
    @param_objs
  end

  def get_param(name)
    get_param_objs
    @param_objs[name.to_sym]
  end

  def from_goodreads_series(goodreads_result)
      self.title = goodreads_result[:title]
      self.description=goodreads_result[:description]
      self.goodreads_id = goodreads_result[:goodreads_id]
  end

    before_validation do
       self.seo_index = (self.title || "").to_seo
    end

end
