require 'acts_as_tree_rails3'

module Roxiware
  # Site Visitor generated comments for blogs, forums, etc.
  class Comment < ActiveRecord::Base
    include ActionView::Helpers::TextHelper
    include Roxiware::BaseModel
    self.table_name="comments"
    ALLOWED_STATUS = %w(moderate publish)
    belongs_to :parent, :polymorphic=>true, :autosave=>true
    belongs_to :post, :polymorphic=>true, :autosave=>true
    belongs_to :comment_author, :counter_cache=>true, :autosave=>true
    acts_as_tree :foreign_key => "parent_id"

    validates_presence_of :comment_date, :message=>"The comment date is missing."
    validates_presence_of :comment_status, :inclusion=> {:in => ALLOWED_STATUS}, :message=>"Invalid comment status."
    validates_presence_of :post_type, :inclusion=>{:in=> %w(Roxiware::Forum::Topic Roxiware::Blog::Post)}

    edit_attr_accessible :comment_status, :as=>[:super, :admin, :user, nil]
    edit_attr_accessible :parent_id, :parent_type, :comment_author_id, :as=>[nil]
    edit_attr_accessible :comment_content, :comment_date, :parent_id, :as=>[:super, :admin, :user, :guest, nil]
    ajax_attr_accessible :comment_content, :comment_date, :parent_id, :comment_status
    
    scope :published, -> { where(:comment_status=>"publish") }
    scope :visible, -> (user) { where((user.blank?) ? "comment_status='publish'" : ((user.is_admin?) ? "" : 'comment_status="publish"')) }

    def visible?(user) 
        (user.present? && user.is_admin?) || (comment_status == "publish")
    end

    def import_wp(comment_node, current_user)
        self.comment_content = comment_node.find_first("wp:comment_content").content
	self.comment_date = comment_node.find_first("wp:comment_date_gmt").content
	self.comment_status = (comment_node.find_first("wp:comment_approved").content == "1") ? "publish" : "moderate"
	comment_user_id = comment_node.find_first("wp:comment_user_id").content
	if(comment_user_id == "1") 
	    comment_author = Roxiware::CommentAuthor.find_or_initialize_by_authtype_and_person_id({:name=>current_user.person.full_name,
						                                               :email=>current_user.email,
								                               :person_id=>current_user.person.id,
								                               :url=>"/people/#{current_user.person.seo_index}",
								                               :comment_object=>self,
								                               :authtype=>"roxiware",
											       :thumbnail_url=>current_user.person.thumbnail_url}, :as=>"");
	    comment_author.person = current_user.person
	else
	    comment_author = Roxiware::CommentAuthor.new({:name=>comment_node.find_first("wp:comment_author").content,
				                          :email=>comment_node.find_first("wp:comment_author_email").content,
							  :url=>comment_node.find_first("wp:comment_author_url").content,
							  :comment_object=>self,
							  :authtype=>"generic",
							  :thumbnail_url=>default_image_path(:person, "thumbnail")}, :as=>"");
	end
	comment_author.save!
    end

    def unread?(last_read)
        
    end

    before_validation() do
       self.comment_content = Sanitize.clean(self.comment_content, Sanitize::Config::RELAXED.merge({:add_attributes => {'a' => {'rel' => 'nofollow'}}}))
    end

    # handle count caching.  We don't use the built in count_cache on the belongs_to as we have
    # multiple counters depending on comment_status
    before_create do
        count_column = ((comment_status == "publish") ? :comment_count : :pending_comment_count)
        self.post.class.increment_counter(count_column, self.post_id)
        self.post.reload
        self.post.touch
    end

    before_destroy do 
        count_column = ((comment_status == "publish") ? :comment_count : :pending_comment_count)
        self.post.class.decrement_counter(count_column, self.post.id)
        self.post.reload
        self.post.touch
    end

    before_update do 
        if comment_status_changed?
           self.post.class.decrement_counter(((comment_status != "publish") ? :comment_count : :pending_comment_count), post.id)
           self.post.class.increment_counter(((comment_status == "publish") ? :comment_count : :pending_comment_count), post.id)
           self.post.reload
           self.post.touch
        end
    end
  end
end