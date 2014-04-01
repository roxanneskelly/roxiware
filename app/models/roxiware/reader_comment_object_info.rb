module Roxiware
  class ReaderCommentObjectInfo < ActiveRecord::Base
    include Roxiware::BaseModel
    self.table_name="reader_comment_object_infos"

    # return only those comment objects that are last_read, with no additional metadata such as ratings, notify indications, etc.
    scope :only_last_read, ->{ where(:rating=>nil, :notify=>nil) }

    belongs_to :reader, :class_name=>"Roxiware::CommentAuthor"
    belongs_to :comment_object, :polymorphic=>true
    

    edit_attr_accessible :last_read, :rating, :notify, :reader, :comment_object, :as=>[:super, :admin, nil]
    ajax_attr_accessible :last_read, :rating, :notify, :reader, :comment_object, :as=>[:super, :admin, nil]
  end
end
