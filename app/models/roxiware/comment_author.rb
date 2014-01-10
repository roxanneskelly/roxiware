module Roxiware
  class CommentAuthor < ActiveRecord::Base
    include ActionView::Helpers::TextHelper
    include Roxiware::BaseModel
    self.table_name="comment_authors"
    ALLOWED_AUTHTYPES = %w(roxiware generic facebook twitter error)

    has_many :comments, :dependent=>:destroy
    belongs_to :person
    has_many :reader_infos, :class_name=>"Roxiware::ReaderCommentObjectInfo", :dependent=>:destroy

    validates_presence_of :email, :if=>Proc.new { |a| (a.authtype == "generic") }, :message=>"You must provide an email address."

    validates :email, :length=>{:maximum=>256,
				:too_long => "Your email address must be no more than ${count} characters."
				}
    validates :url, :length=>{	:maximum=>256,
				:too_long => "Your url must be no more than ${count} characters."}
    validates :thumbnail_url, :length=>{	:maximum=>256,
				:too_long => "Your thumbnail url must be no more than ${count} characters."}
    validates_presence_of :name, :if=>Proc.new { |a| (a.authtype == "generic") }, :message=>"You must provide a name"
    validates :name, :length=>{	:maximum=>256,
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


    def display_name
        # name is really their display_name/nickname
        return self.name if self.name.present?

        # if they've not set a display_name, then default
        # to semantics based on various authtypes.  for now
        # just return full name from person if present, otherwise
        # assume facebook/twitter/etc. would have set the name initially

        case authtype
        when "roxiware"
           person.full_name
        else
           "Unknown"
        end
    end

    def get_author_url
        case authtype
        when "roxiware"
            self.person.present? ? "/people/#{self.person.seo_index}" : nil
        when "twitter"
            "http://www.twitter.com/#{uid}"
        when "facebook"
            "http://www.facebook.com/#{uid}"
        else
            self.url
        end
    end

    def get_thumbnail_url
        case authtype
        when "roxiware"
           (person.thumbnail if person.present?) || default_image_path(:person, "thumbnail")
        when "facebook"
           "http://graph.facebook.com/#{uid}/picture?type=square"
        when "twitter"
	   self.thumbnail_url || default_image_path(:person, "thumbnail")
        else
            default_image_path(:person, "thumbnail")
        end
    end

    def self.comment_author_from_user(user)
        comment_author = Roxiware::CommentAuthor.where(:authtype=>"roxiware", :person_id=>user.person.id).first_or_initialize
	comment_author.person = user.person
        comment_author
    end

    def self.comment_author_from_params(params)
        comment_author = Roxiware::CommentAuthor.new
	comment_author.assign_attributes(params, :as=>"")
        comment_author.authtype="generic"
        comment_author
    end

    def self.comment_author_from_token(token)
        begin
	    auth_user_token = Roxiware::AuthHelpers::AuthUserToken.new(token)
	    case auth_user_token.auth_kind
		when "facebook","twitter"
		    token_attributes = auth_user_token.token_attributes
		    comment_author = Roxiware::CommentAuthor.where(:authtype=>token_attributes[:authtype], :uid=>token_attributes[:uid]).first_or_create
		    comment_author.assign_attributes(token_attributes, :as=>"")
		    comment_author.save!
	    else
		raise Exception.new("Unsupport authentication method")
	    end
        rescue Exception=>e
	    puts e.message
	    comment_author = Roxiware::CommentAuthor.new()
            comment_author.authtype = "expired"
        end
        comment_author
    end
  end
end