require 'devise'
require 'acts_as_tree_rails3'
module Roxiware
 module Blog
  class Post < ActiveRecord::Base
    include ActionView::Helpers::TextHelper
    include Roxiware::BaseModel
    self.table_name="blog_posts"
    ALLOWED_STATUS = %w(new publish draft trash)
    ALLOWED_COMMENT_PERMISSIONS = %w(open moderate closed hide)
    belongs_to :person
    has_many :comments, :dependent=>:destroy, :inverse_of=>:post
    validates_presence_of :person_id
    validates_presence_of :guid
    validates_uniqueness_of :guid
    validates_presence_of :post_date
    validates_presence_of :post_exerpt
    validates_presence_of :post_link
    validates_uniqueness_of :post_link
    validates_presence_of :post_title
    validates :post_title, :length => {:minimum=>2}
    validates_presence_of :post_content
    validates_presence_of :post_status, :inclusion=> {:in => ALLOWED_STATUS}
    validates_presence_of :comment_permissions, :inclusion=> {:in => ALLOWED_COMMENT_PERMISSIONS}

    edit_attr_accessible :post_content, :post_date, :post_exerpt, :post_title, :post_status, :comment_permissions, :as=>[:admin, :user, nil]
    edit_attr_accessible :person_id, :as=>[:admin, nil]
    edit_attr_accessible :guid, :post_link, :post_exerpt, :as=>[nil]
    ajax_attr_accessible :guid, :post_date, :post_exerpt, :post_link, :post_title, :post_content, :person_id, :post_status, :comment_permissions
    
    scope :published, where(:post_status=>"publish")
    scope :visible, lambda{|role, person_id| where(role=="admin"?"":["person_id = ? OR post_status='publish'", person_id])}

    before_validation() do
       seo_index = self.post_title.downcase.gsub(/[^a-z0-9]+/i, '-')
       self.guid = self.post_link = "/blog/" + self.post_date.strftime("%Y/%-m/%-d/") + seo_index
       self.post_exerpt = Sanitize.clean(truncate(self.post_content, :length => Roxiware.blog_exerpt_length),Sanitize::Config::RELAXED)
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

    validates_presence_of :comment_content
    validates_presence_of :post_id, :null=>false
    validates_presence_of :comment_date
    validates_presence_of :comment_status, :inclusion=> {:in => ALLOWED_STATUS}
    validates_presence_of :comment_author
    validates_presence_of :comment_author_email


    edit_attr_accessible :comment_status, :as=>[:admin, :user, nil]
    edit_attr_accessible :person_id, :as=>[:admin, nil]
    edit_attr_accessible :parent_id, :post_id, :as=>[nil]
    edit_attr_accessible :comment_content, :comment_date, :comment_author, :comment_author_email, :comment_author_url, :parent_id, :as=>[:admin, :user, :guest, nil]
    ajax_attr_accessible :comment_content, :comment_date, :comment_author, :comment_author_email, :comment_author_url, :person_id, :parent_id, :comment_status
    
    scope :published, where(:comment_status=>"publish")
    scope :visible, lambda{|role, person_id| where(role=="admin"?"":["person_id = ? OR comment_status='publish'", person_id])}

    before_validation() do
       self.comment_content = Sanitize.clean(self.comment_content, Sanitize::Config::RELAXED)
    end
  end

  class TermRelationship < ActiveRecord::Base
    include Roxiware::BaseModel
    self.table_name = "blog_term_relationship"
    has_one :blog_post
    has_one :blog_term

    validates_presence_of :blog_post, :null=>false
    validates_presence_of :blog_term, :null=>false


  end



  class Term < ActiveRecord::Base
    belongs_to :blog_term_taxonomy
    has_many :blog_term_relationships

    validates_presence_of :blog_term_taxonomy_id, :null=>false
    validates_presence_of :name, :null=>false
    validates_presence_of :seo_index, :null=>false
    validates_uniqueness_of :seo_index, :scope=>:blog_term_taxonomy_id

    attr_accessible :name, :seo_index

  end


  class TermTaxonomy < ActiveRecord::Base
    has_many :blog_terms
    attr_accessible :description, :name, :seo_index
  end

 end
end
