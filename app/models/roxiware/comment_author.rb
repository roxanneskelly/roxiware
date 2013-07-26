module Roxiware
  # author of a comment
  class CommentAuthor < ActiveRecord::Base
    include ActionView::Helpers::TextHelper
    include Roxiware::BaseModel
    self.table_name="comment_authors"
    ALLOWED_AUTHTYPES = %w(roxiware generic facebook twitter)

    validates_presence_of :name
    has_one :comment, :dependent=>:destroy, :autosave=>true
    belongs_to :person

    validates :email, :length=>{:minimum=>1,
                                :too_short => "The you must provide an email address.",
				:maximum=>256,
				:too_long => "Your email address must be no more than ${count} characters."
				}
    validates :url, :length=>{
				:maximum=>256,
				:too_long => "Your url must be no more than ${count} characters."
				}

    validates :name, :length=>{
				:maximum=>256,
				:too_long => "Your name must be no more than ${count} characters."
				}


    edit_attr_accessible :person_id, :comment_object_type, :as=>[:super, :admin, nil]
    edit_attr_accessible :name, :email, :url, :authtype, :uid, :comment_id, :as=>[:super, :admin, :user, :guest, nil]
    ajax_attr_accessible :name, :email, :url, :authtype, :uid, :comment_id, :as=>[:super, :admin, :user, :guest, nil]

    def thumbnail_url
        case authtype
        when "roxiware"
           person.thumbnail_url
        else
            default_image_path(:person, "thumbnail")
        end
    end
  end
end