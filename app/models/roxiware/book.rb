class Roxiware::Book < ActiveRecord::Base
  include Roxiware::BaseModel
  self.table_name= "books"

  has_many        :params, :class_name=>"Roxiware::Param::Param", :as=>:param_object, :autosave=>true, :dependent=>:destroy
  has_many        :book_series_joins, :autosave=>true, :dependent=>:destroy
  has_many        :book_series, :through=>:book_series_joins
  has_one         :goodreads_id_join, :as=>:grent, :autosave=>true, :dependent=>:destroy

  validates_presence_of :title
  validates_uniqueness_of :seo_index, :allow_nil=>true, :allow_blank=>true, :message=>"The book has already been added."


  edit_attr_accessible :seo_index, :goodreads_id, :description, :image, :isbn, :isbn13, :large_image, :small_image, :title, :bookstores, :as=>[:super, :admin, :user, nil]
  ajax_attr_accessible :seo_index, :goodreads_id, :description, :image, :isbn, :isbn13, :large_image, :small_image, :title, :bookstores, :as=>[:super, :admin, :user, :guest, nil]


  EDITIONS = {
     :mass_market_paperback=>"Mass Market Paperback",
     :trade_paperback=>"Mass Market Paperback",
     :hardcover=>"Hardcover",
     :kindle=>"Kindle",
     :audio=>"Audio"
  }

  STORES = {
    "amazon"=>"Amazon",
    "barnesandnoble"=>"Barnes and Noble",
    "kobo"=>"Kobo",
    "sony"=>"Sony"


  }

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

  def book_id
      if isbn.present?
        isbn
      elsif isbn13.present?
        isbn13
      else
        id
      end
  end

  def bookstores
     get_param("bookstores").a.collect{|bookstore| bookstore.to_jstree_data}
  end

  def from_goodreads_book(goodreads_result)
      self.title = goodreads_result[:title]
      self.isbn=goodreads_result[:isbn]
      self.isbn13=goodreads_result[:isbn13]
      self.large_image=goodreads_result[:large_image]
      self.image=goodreads_result[:image]
      self.small_image=goodreads_result[:small_image]
      self.description=goodreads_result[:description]
      self.goodreads_id = goodreads_result[:goodreads_id]

     stores =  params.build({:param_class=>"local", 
                                     :description_guid=>"6C16D934-0643-48EC-806C-95BDAF52E078",
                                     :name=>"bookstores",
                                     :value=>""}, :as=>"")
    Roxiware::Book::STORES.each do |key, value|
       store = stores.params.build({:param_class=>"local", :description_guid=>"E59B2EB2-6867-475D-A691-ABF1A68E5BE7",
                                        :name=>key}, :as=>"")

       store.params.build({:param_class=>"local", :description_guid=>"5B7766EA-3FAD-48DB-9894-756F1B14DB69",
                                        :name=>"store_id", :value=>key}, :as=>"");

       editions = store.params.build({:param_class=>"local", :description_guid=>"E73E1207-CB64-44AB-8F1C-2032AD6A34B4",
                                        :name=>"children", :value=>""}, :as=>"");
       if isbn.present?
	   edition = editions.params.build({:param_class=>"local", :description_guid=>"4014F256-277D-4B58-8375-E1560524EA20",
						 :name=>"default", :value=>""}, :as=>"")
           edition.params.build({:param_class=>"local", :description_guid=>"2BEBB288-5015-4D05-A3A1-224EE4D3D37F",
				          :name=>"link", :value=>get_sale_link(key)}, :as=>"")

	   edition.params.build({:param_class=>"local", :description_guid=>"89E14824-F9E5-46EA-9A73-584997D972B2",
						       :name=>"name", :value=>"Default"}, :as=>"")
       end
    end
  end

  def get_edition_name(edition)
      EDITIONS[edition]
  end

  def get_sale_link(store_id, opts = {})
     isbn = opts[:isbn] || self.isbn
     case store_id
        when "amazon"
	   "http://www.amazon.com/gp/product/%s/ref=as_li_qf_sp_asin_tl?ie=UTF8&&linkCode=as2&tag=%s"% [isbn, 
                  Roxiware::Param::Param.application_param_val("system", "amazon_associate_id")]
        when "barnesandnoble"
	   "http://www.barnesandnoble.com/s/%s" % [isbn]
	when "kobo"
	   "http://www.kobobooks.com/search/search.html?q="+URI::encode(self.title + " ")
	when "sony"
	   "https://ebookstore.sony.com/search?keyword="+URI::encode(self.title + " ")
     else
        nil
     end
  end

  def get_edition_name(edition)
     @@editions[edition.to_sym]
  end

  before_validation do
     self.seo_index = (self.title || "").to_seo
  end
end
