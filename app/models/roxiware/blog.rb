require 'devise'
require 'acts_as_tree_rails3'
module Roxiware
 module Blog

  @last_update = DateTime.now
  def self.last_update
    @last_update
  end

  class Post < ActiveRecord::Base
    include ActionView::Helpers::TextHelper
    include Roxiware::BaseModel
    self.table_name="blog_posts"
    ALLOWED_STATUS = %w(new publish draft trash)
    ALLOWED_COMMENT_PERMISSIONS = %w(default open moderate closed hide)
    belongs_to :person
    has_many :comments, :dependent=>:destroy, :inverse_of=>:post
    has_many :term_relationships, :as=>:term_object, :class_name=>"Roxiware::Terms::TermRelationship", :dependent=>:destroy, :autosave=>true
    has_many :terms, :through=>:term_relationships, :class_name=>"Roxiware::Terms::Term"

    validates_presence_of :person_id, :message=>"The person id is missing."
    validates_presence_of :guid, :message=>"The guid is missing."
    validates_presence_of :post_link, :message=>"The post link is missing."
    validates_uniqueness_of :post_link, :message=>"Duplicate post title for this date."

    validates_presence_of :post_date, :message=>"The post must have a post date"

    validates :post_content, :length=>{:minimum=>5,
                                      :too_short => "The post must contain at least  %{count} characters.",
				      :maximum=>100000,
				      :too_long => "The post can be no larger than ${count} characters."
				      }

    validates :post_title, :length=>{:minimum=>5,
                                      :too_short => "The post title must at least  %{count} characters.",
				      :maximum=>256,
				      :too_long => "The post title can be no larger than ${count} characters."
				      }

    validates_presence_of :post_status, :inclusion=> {:in => ALLOWED_STATUS}, :message=>"Invalid post status."
    validates_presence_of :comment_permissions, :inclusion=> {:in => ALLOWED_COMMENT_PERMISSIONS}, :message=>"Invalid comment permissions."

    edit_attr_accessible :post_content, :post_date, :post_exerpt, :post_title, :post_status, :comment_permissions, :category_name, :tag_csv, :as=>[:admin, :user, nil]
    edit_attr_accessible :person_id, :as=>[:admin, nil]
    edit_attr_accessible :post_exerpt, :as=>[nil]
    ajax_attr_accessible :guid, :post_date, :post_exerpt, :post_link, :post_title, :post_content, :person_id, :post_status, :comment_permissions, :tag_csv, :category_name
    
    scope :published, where(:post_status=>"publish")
    scope :visible, lambda{|role, person_id| where(role=="admin"?"":["person_id = ? OR post_status='publish'", person_id])}

    after_save do
      @@last_update = DateTime.now
    end

    def set_term_ids(term_ids, taxonomy_id)
        current_term_ids_for_taxonomy = self.terms.select {|term| term.term_taxonomy_id == taxonomy_id }.collect{|term| term.id}

        term_ids_not_for_taxonomy = self.term_ids.to_set - current_term_ids_for_taxonomy
	added_term_ids = term_ids.to_set - current_term_ids_for_taxonomy

	deleted_term_ids = current_term_ids_for_taxonomy.to_set - term_ids
	self.term_ids = term_ids_not_for_taxonomy.merge(term_ids).to_a
    end

    def tag_ids
      self.terms.select {|term| term.term_taxonomy_id == Roxiware::Terms::TermTaxonomy::TAG_ID }.collect{|term| term.id}
    end

    def tag_ids=(tag_ids)
        self.set_term_ids(tag_ids, Roxiware::Terms::TermTaxonomy::TAG_ID)
    end
   
    def tag_csv
       self.terms.where(:term_taxonomy_id => Roxiware::Terms::TermTaxonomy::TAG_ID).map{|term| term.name}.join(", ")
    end

    def tag_csv=(csv)
       tag_strings = csv.split(",").collect {|x| x.gsub(/[^a-z0-9]+/i,' ').gsub(/\s+/,' ').strip.capitalize}.select{|y| !y.empty?}
       self.tag_ids = Roxiware::Terms::Term.get_or_create(tag_strings, Roxiware::Terms::TermTaxonomy::TAG_ID).map{|term| term.id}
    end

    def tags
      self.terms.select {|term| term.term_taxonomy_id == Roxiware::Terms::TermTaxonomy::TAG_ID }
    end

    def category_ids
      self.terms.select {|term| term.term_taxonomy_id == Roxiware::Terms::TermTaxonomy::CATEGORY_ID }.collect{|term| term.id}
    end

    def category_ids=(category_ids)
        self.set_term_ids(category_ids, Roxiware::Terms::TermTaxonomy::CATEGORY_ID)
    end

    def categories
      self.terms.select {|term| term.term_taxonomy_id == Roxiware::Terms::TermTaxonomy::CATEGORY_ID }
    end

    def category_name
      if self.categories.first
         self.categories.first.name || ""
      else
        ""
      end
    end
    
    def category_name=(set_name)
       self.category_ids = Roxiware::Terms::Term.get_or_create([set_name], Roxiware::Terms::TermTaxonomy::CATEGORY_ID).map{|term| term.id}
    end

    before_validation() do
       seo_index = self.post_title.downcase.gsub(/[^a-z0-9]+/i, '-')
       self.guid = self.post_link = "/blog/" + self.post_date.strftime("%Y/%-m/%-d/") + seo_index
       self.post_exerpt = Sanitize.clean(truncate(Sanitize.clean(self.post_content, Sanitize::Config::RELAXED), :length => Roxiware.blog_exerpt_length, :omission=>""),Sanitize::Config::RELAXED)
       self.post_content = Sanitize.clean(self.post_content, Sanitize::Config::RELAXED)
    end
  end

  class Comment < ActiveRecord::Base
    include ActionView::Helpers::TextHelper
    include Roxiware::BaseModel
    self.table_name="blog_comments"
    ALLOWED_STATUS = %w(moderate publish)
    belongs_to :person
    belongs_to :post
    acts_as_tree :foreign_key => "parent_id"

    validates :comment_content, :length=>{:minimum=>5,
                                      :too_short => "The comment must contain at least  %{count} characters.",
				      :maximum=>10000,
				      :too_long => "The comment can be no larger than ${count} characters."
				      }
    validates_presence_of :post_id, :null=>false, :message=>"The post id is missing."
    validates_presence_of :comment_date, :message=>"The comment date is missing."
    validates_presence_of :comment_status, :inclusion=> {:in => ALLOWED_STATUS}, :message=>"Invalid comment status."
    validates_presence_of :comment_author

    validates :comment_author_email, :length=>{:minimum=>1,
                                      :too_short => "The you must provide an email address.",
				      :maximum=>256,
				      :too_long => "Your email address must be no more than ${count} characters."
				      }
    validates :comment_author_url, :length=>{
				      :maximum=>256,
				      :too_long => "Your url must be no more than ${count} characters."
				      }

    validates :comment_author, :length=>{
				      :maximum=>256,
				      :too_long => "Your name must be no more than ${count} characters."
				      }


    edit_attr_accessible :comment_status, :as=>[:admin, :user, nil]
    edit_attr_accessible :person_id, :as=>[:admin, nil]
    edit_attr_accessible :parent_id, :post_id, :as=>[nil]
    edit_attr_accessible :comment_content, :comment_date, :comment_author, :comment_author_email, :comment_author_url, :parent_id, :as=>[:admin, :user, :guest, nil]
    ajax_attr_accessible :comment_content, :comment_date, :comment_author, :comment_author_email, :comment_author_url, :person_id, :parent_id, :comment_status
    
    scope :published, where(:comment_status=>"publish")
    scope :visible, lambda{|role, person_id| where(role=="admin"?"":["person_id = ? OR comment_status='publish'", person_id])}

    before_validation() do
       self.comment_content = Sanitize.clean(self.comment_content, Sanitize::Config::RELAXED.merge({:add_attributes => {'a' => {'rel' => 'nofollow'}}}))
    end
  end
 end
end
