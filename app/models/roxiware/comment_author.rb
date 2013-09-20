module Roxiware
  # author of a comment
  class CommentAuthor < ActiveRecord::Base
    include ActionView::Helpers::TextHelper
    include Roxiware::BaseModel
    self.table_name="comment_authors"
    ALLOWED_AUTHTYPES = %w(roxiware generic facebook twitter)

    validates_presence_of :name
    has_many :comments, :dependent=>:destroy
    belongs_to :person

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


    edit_attr_accessible :person_id, :comment_object_type, :as=>[:super, :admin, nil]
    edit_attr_accessible :name, :email, :url, :authtype, :uid, :comment_id, :thumbnail_url, :likes, :blocked, :comments_count, :as=>[:super, :admin, :user, :guest, nil]
    ajax_attr_accessible :name, :email, :url, :authtype, :uid, :comment_id, :thumbnail_url, :likes, :blocked, :comments_count, :as=>[:super, :admin, :user, :guest, nil]

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
           person.thumbnail_url || default_image_path(:person, "thumbnail")
        when "facebook"
           "http://graph.facebook.com/#{uid}/picture?type=square"
        when "twitter"
	   self.thumbnail_url || default_image_path(:person, "thumbnail")
        else
            default_image_path(:person, "thumbnail")
        end
    end

    def self.comment_author_from_params(params)
        current_user = params[:current_user]
	if current_user.present?
	    comment_author = Roxiware::CommentAuthor.find_or_initialize_by_authtype_and_person_id({:name=>current_user.person.full_name,
						                                               :email=>current_user.email,
								                               :person_id=>current_user.person.id,
								                               :url=>"/people/#{current_user.person.seo_index}",
								                               :comment_object=>@comment,
								                               :authtype=>"roxiware",
											       :thumbnail_url=>current_user.person.thumbnail_url}, :as=>"");
	    comment_author.person = current_user.person
	else
	    case params[:comment_author_authtype]
	        when "generic"
	           comment_author = Roxiware::CommentAuthor.new({:name=>params[:comment_author],
						                    :email=>params[:comment_author_email],
								    :url=>params[:comment_author_url],
								    :comment_object=>@comment,
								    :authtype=>"generic",
								    :thumbnail_url=>default_image_path(:person, "thumbnail")}, :as=>"");
	        when "facebook","twitter"
	           begin
		       auth_user_token = Roxiware::AuthHelpers::AuthUserToken.new(params[:comment_author_auth_token])
		       token_attributes = auth_user_token.token_attributes
		       token_attributes[:comment_object]=@comment
		       comment_author = Roxiware::CommentAuthor.find_or_initialize_by_authtype_and_uid(token_attributes, :as=>"")
		       comment_author.update_attributes(token_attributes, :as=>"")
		   rescue Exception => e
		       comment_author = Roxiware::CommentAuthor.new()
		       comment_author.errors.add("exception", e.message())
		   end
	    else
	       comment_author = Roxiware::CommentAuthor.new()
	       comment_author.errors.add("exception", "Unsupported authentication method")
           end
        end
	comment_author
    end
  end
end