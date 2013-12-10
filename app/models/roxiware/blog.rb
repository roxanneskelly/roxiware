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
    ALLOWED_STATUS = %w(publish draft trash)
    ALLOWED_COMMENT_PERMISSIONS = %w(default open moderate closed hide)
    belongs_to :person
    has_many :comments, :class_name=>"Roxiware::Comment", :dependent=>:destroy, :as=>:post
    has_many :term_relationships, :as=>:term_object, :class_name=>"Roxiware::Terms::TermRelationship", :dependent=>:destroy, :autosave=>true
    has_many :terms, :through=>:term_relationships, :class_name=>"Roxiware::Terms::Term", :autosave=>true

    validates_presence_of :person_id, :message=>"The person id is missing."
    validates_presence_of :guid, :message=>"The guid is missing."
    validates_presence_of :post_link, :message=>"The post link is missing."
    validates_uniqueness_of :post_link, :message=>"Duplicate post title for this date."

    validates_presence_of :post_date, :message=>"The post must have a post date"
    default_scope { includes(:terms)}

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
    
    scope :published, -> { where(:post_status=>"publish") }
    scope :visible, ->(user) {where((user.blank?) ? "post_status='publish'" : ((user.is_admin?) ? "" : "person_id = #{user.person_id || 0} OR post_status='publish'")) }

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
      self.terms.select{|term| term.term_taxonomy_id == Roxiware::Terms::TermTaxonomy.taxonomy_id(Roxiware::Terms::TermTaxonomy::TAG_NAME)}
    end

    def category_ids
       self.categories.collect{|category| category.id}
    end

    def category_ids=(category_ids)
        self.term_ids = (self.tag_ids.to_set + category_ids.to_set).to_a
    end

    def categories
      self.terms.select{|term| term.term_taxonomy_id == Roxiware::Terms::TermTaxonomy.taxonomy_id(Roxiware::Terms::TermTaxonomy::CATEGORY_NAME)}
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

    def snippet(post_content_length, options={}, &block)
	(Sanitize.clean(truncate(self.post_content, :escape=>false, :length => post_content_length, :omission=>"", :separator=>" "), options[:sanitizer] || Roxiware::Sanitizer::EXTENDED_SANITIZER) + block.call)
    end

    def post_image
        self.post_image_url
    end
    def post_video
        self.post_video_url
    end

    before_validation() do
        if self.post_title_changed?
            seo_index = self.post_title.to_seo
            self.guid = self.post_link = "/"+self.blog_class+"/" + self.post_date.strftime("%Y/%-m/%-d/") + seo_index
        end
	if self.post_content_changed?
            self.post_exerpt = self.snippet(Roxiware.blog_exerpt_length, Roxiware::Sanitizer::EXTENDED_SANITIZER){""}
            
	    video_url = self.post_content[/iframe.*?src="((http|https):\/\/(www\.youtube\.com\/embed\/|youtu.be\/)[^\"]+)/i,1]
	    puts "VIDEO URL #{video_url.inspect}"
	    video_uri = URI(video_url)
            if(video_uri.present?)
		case video_uri.host
		    when "youtu.be"
			video_id = video_uri.path
			self.post_type="youtube_video"
			self.post_image_url ||= "http://img.youtube.com/vi/#{video_id}/0.jpg"
			self.post_thumbnail_url ||= "http://img.youtube.com/vi/#{video_id}/1.jpg"
			self.post_video_url = "http://www.youtube.com/embed/#{video_id}"
		    when "www.youtube.com"
			video_id = Pathname.new(video_uri.path).basename
			self.post_type="youtube_video"
			self.post_image_url ||= "http://img.youtube.com/vi/#{video_id}/0.jpg"
			self.post_thumbnail_url ||= "http://img.youtube.com/vi/#{video_id}/1.jpg"
			self.post_video_url = "http://www.youtube.com/embed/#{video_id}"
		    else
			self.post_image_url = self.post_content[/img.*?src="(.*?)"/i,1]
			self.post_thumbnail_url = self.post_content[/img.*?src="(.*?)"/i,1]
			if(self.post_image_url.present?)
			    self.post_type="image"
			else
			    self.post_type="text"
			end
		end
            end
        end
    end

    def import_wp(item_node, current_user)
        self.post_title = item_node.find_first("title").content
	self.post_content = item_node.find_first("content:encoded").content
	self.post_date = item_node.find_first("wp:post_date_gmt").content
	self.comment_permissions = item_node.find_first("wp:comment_status").content
	self.post_status = item_node.find_first("wp:status").content
	category = item_node.find_first("category")
	self.category_name = category.content if category.present?
	comment_nodes = item_node.find("wp:comment")
	comment_nodes.each do |comment_node|
	    comment = Roxiware::Comment.new()
	    comment.import_wp(comment_node, current_user)
	    self.comments << comment
	end
    end
  end
 end
end
