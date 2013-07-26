require 'devise'
require 'acts_as_tree_rails3'
module Roxiware
 module Blog

  @last_update = DateTime.now
  def self.last_update
    @last_update
  end
  def self.notify_update
      @last_update = DateTime.now
  end

  class Post < ActiveRecord::Base
    include ActionView::Helpers::TextHelper
    include Roxiware::BaseModel
    self.table_name="blog_posts"
    ALLOWED_STATUS = %w(new publish draft trash)
    ALLOWED_COMMENT_PERMISSIONS = %w(default open moderate closed hide)
    belongs_to :person
    has_many :comments, :dependent=>:destroy
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

    edit_attr_accessible :post_content, :blog_class, :post_date, :post_exerpt, :post_title, :post_status, :comment_permissions, :category_name, :tag_csv, :as=>[:super, :admin, :user, nil]
    edit_attr_accessible :person_id, :as=>[:super, :admin, nil]
    edit_attr_accessible :post_exerpt, :as=>[nil]
    ajax_attr_accessible :guid, :blog_class, :post_date, :post_exerpt, :post_link, :post_title, :post_content, :person_id, :post_status, :comment_permissions, :tag_csv, :category_name
    
    scope :published, where(:post_status=>"publish")
    scope :visible, lambda{|user| where((user.blank?) ? "post_status='publish'" : ((user.is_admin?) ? "" : "person_id = #{user.person_id || 0} OR post_status='publish'")) }

    after_save do
      Roxiware::Blog.notify_update
    end

    def resolve_comment_permissions
        if comment_permissions != "default"
	    comment_permissions
        else
	    Roxiware::Param::Param.application_param_val("blog", "blog_comment_permissions")
        end
    end

    def tag_ids
      self.tags.collect{|term| term.id}
    end

    def tag_ids=(tag_ids)
        self.term_ids = (self.category_ids.to_set + tag_ids.to_set).to_a
    end
   
    def tag_csv
       self.tags.collect{|term| term.name}.join(", ")
    end

    def tag_csv=(csv)
       tag_strings = csv.split(",").collect {|x| x.gsub(/[^a-z0-9]+/i,' ').gsub(/\s+/,' ').strip.capitalize}.select{|y| !y.empty?}
       self.tag_ids = Roxiware::Terms::Term.get_or_create(tag_strings, Roxiware::Terms::TermTaxonomy::TAG_NAME).map{|term| term.id}
    end

    def tags
      self.terms.where(:term_taxonomy_id=>Roxiware::Terms::TermTaxonomy.taxonomy_id(Roxiware::Terms::TermTaxonomy::TAG_NAME))
    end

    def category_ids
       self.categories.collect{|category| category.id}
    end

    def category_ids=(category_ids)
        self.term_ids = (self.tag_ids.to_set + category_ids.to_set).to_a
    end

    def categories
      self.terms.where(:term_taxonomy_id=>Roxiware::Terms::TermTaxonomy.taxonomy_id(Roxiware::Terms::TermTaxonomy::CATEGORY_NAME))
    end

    def category_name
      if self.categories.first
         self.categories.first.name || ""
      else
        ""
      end
    end
    
    def category_name=(set_name)
       self.category_ids = Roxiware::Terms::Term.get_or_create([set_name], Roxiware::Terms::TermTaxonomy::CATEGORY_NAME).map{|term| term.id}
    end

    before_validation() do
       seo_index = self.post_title.downcase.gsub(/[^a-z0-9]+/i, '-')
       self.guid = self.post_link = "/"+self.blog_class+"/" + self.post_date.strftime("%Y/%-m/%-d/") + seo_index
       self.post_exerpt = Sanitize.clean(truncate(Sanitize.clean(self.post_content, Roxiware::Sanitizer::BASIC_SANITIZER), :length => Roxiware.blog_exerpt_length, :omission=>""),Roxiware::Sanitizer::BASIC_SANITIZER)
    end
  end

 end
end
