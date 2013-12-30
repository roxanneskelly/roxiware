module Roxiware
  class CommentAuthor < ActiveRecord::Base
    include ActionView::Helpers::TextHelper
    include Roxiware::BaseModel
    self.table_name="comment_authors"
    ALLOWED_AUTHTYPES = %w(roxiware generic facebook twitter)

    validates_presence_of :name
    has_many :comments, :dependent=>:destroy
    belongs_to :person
    has_many :reader_infos, :class_name=>"Roxiware::ReaderCommentObjectInfo"

    validates :email, :length=>{:minimum=>1,
                                :too_short => "The you must provide an email address.",
				:maximum=>256,
				:too_long => "Your email address must be no more than ${count} characters."
				}, :if=>Proc.new { |a| (a.authtype == "generic") }

    validates :url, :length=>{
				:maximum=>256,
				:too_long => "Your url must be no more than ${count} characters."
				}

    validates :name, :length=>{
				:maximum=>256,
				:too_long => "Your name must be no more than ${count} characters."
				}


    edit_attr_accessible :person_id,:as=>[:super, :admin, nil]
    edit_attr_accessible :name, :email, :url, :authtype, :uid, :thumbnail_url, :likes, :blocked, :comments_count, :as=>[:super, :admin, :user, :guest, nil]
    ajax_attr_accessible :name, :email, :url, :authtype, :uid, :thumbnail_url, :likes, :blocked, :comments_count, :as=>[:super, :admin, :user, :guest, nil]

    before_validation() do
	 if !(self.url.nil? || self.url.empty?)
	   parsed_uri = URI::parse(self.url)
	   parsed_uri.scheme = 'http' if parsed_uri.scheme.nil?
	   if parsed_uri.host.nil?
	     split_path = parsed_uri.path.split("/")
	     split_path.shift if split_path[0].blank?
	     parsed_uri.host = split_path[0]
	     parsed_uri.path = "/"+split_path[1..-1].join("/")
	   end
	   self.url = parsed_uri.to_s
	end
    end

    def get_thumbnail_url
        case authtype
        when "roxiware"
           person.thumbnail || default_image_path(:person, "thumbnail")
        when "facebook"
           "http://graph.facebook.com/#{uid}/picture?type=square"
        when "twitter"
	   self.thumbnail_url || default_image_path(:person, "thumbnail")
        else
            default_image_path(:person, "thumbnail")
        end
    end

    def self.comment_author_from_user(user)
        comment_author = Roxiware::CommentAuthor.where(:authtype=>"roxiware", :person_id=>current_user.person.id).first_or_initialize
	comment_author.person = current_user.person
    end

    def self.comment_author_from_token(token)
        auth_user_token = Roxiware::AuthHelpers::AuthUserToken.new(token) if token.present?
	return nil if auth_user_token.blank?

        case auth_user_token.auth_kind
	    when "facebook","twitter"
	        begin
		    token_attributes = auth_user_token.token_attributes
		    comment_author = Roxiware::CommentAuthor.where(:authtype=>token_attributes[:authtype], :uid=>token_attributes[:uid]).first_or_create
		    comment_author.assign_attributes(token_attributes, :as=>"")
		    comment_author.save!
		rescue Exception => e
		   comment_author = Roxiware::CommentAuthor.new()
		   comment_author.errors.add("exception", e.message())
            end
	else
	    comment_author = Roxiware::CommentAuthor.new()
	    comment_author.errors.add("exception", "Unsupported authentication method")
        end
	comment_author
    end
  end
end