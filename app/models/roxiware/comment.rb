require 'acts_as_tree_rails3'

module Roxiware
  # Site Visitor generated comments for blogs, forums, etc.
  class Comment < ActiveRecord::Base
    include ActionView::Helpers::TextHelper
    include Roxiware::BaseModel
    self.table_name="comments"
    ALLOWED_STATUS = %w(moderate publish)
    belongs_to :parent, :polymorphic=>true
    belongs_to :comment_author, :autosave=>true, :dependent=>:destroy
    acts_as_tree :foreign_key => "parent_id"

    validates :comment_content, :length=>{:minimum=>5,
                                      :too_short => "The comment must contain at least  %{count} characters.",
				      :maximum=>10000,
				      :too_long => "The comment can be no larger than ${count} characters."
				      }
    validates_presence_of :comment_date, :message=>"The comment date is missing."
    validates_presence_of :comment_status, :inclusion=> {:in => ALLOWED_STATUS}, :message=>"Invalid comment status."


    edit_attr_accessible :comment_status, :as=>[:super, :admin, :user, nil]
    edit_attr_accessible :parent_id, :parent_type, :comment_author_id, :as=>[nil]
    edit_attr_accessible :comment_content, :comment_date, :parent_id, :as=>[:super, :admin, :user, :guest, nil]
    ajax_attr_accessible :comment_content, :comment_date, :parent_id, :comment_status
    
    scope :published, where(:comment_status=>"publish")
    scope :visible, lambda{|user| where((user.blank?) ? "comment_status='publish'" : ((user.is_admin?) ? "" : "comment_status='publish'")) }
  

    before_validation() do
       self.comment_content = Sanitize.clean(self.comment_content, Sanitize::Config::RELAXED.merge({:add_attributes => {'a' => {'rel' => 'nofollow'}}}))
    end
  end
end