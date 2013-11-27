module Roxiware
  module Forum
    # major group of boards
    class BoardGroup < ActiveRecord::Base
        include Roxiware::BaseModel
        self.table_name="forum_board_groups"
        has_many :boards
        default_scope order(:display_order)


        validates_presence_of :name
        validates :name, :length=>{:minimum=>1,
                                   :too_short => "The name must contain at least  %{count} characters.",
				      :maximum=>255,
				      :too_long => "The name can be no larger than ${count} characters."
				      }
	validates_presence_of :display_order
	edit_attr_accessible :name, :display_order, :as=>[nil, :super, :admin]
	ajax_attr_accessible :name, :display_order
    end

    class Board < ActiveRecord::Base
        include Roxiware::BaseModel
        self.table_name="forum_boards"
	has_many :topics, :dependent=>:destroy, :autosave=>true
        has_many :posts, :through=>:topics, :source=>:comments, :class_name=>"Roxiware::Comment"
        belongs_to :board_group
        belongs_to :last_post, :class_name=>"Roxiware::Comment"
        default_scope order(:display_order)
        ALLOWED_TOPIC_PERMISSIONS = %w(open moderate closed hide)

        validates :description, :length=>{:maximum=>255,
				      :too_long => "The description can be no larger than ${count} characters."
				      }
        validates :name, :length=>{:minimum=>2, :too_short=>"The name can be no shorter than ${count} characters.",
                                    :maximum=>255,
				      :too_long => "The name can be no larger than ${count} characters."
				      }
	validates_presence_of :display_order
	edit_attr_accessible :name, :permissions, :description, :display_order, :board_group_id, :as=>[nil, :super, :admin]
	ajax_attr_accessible :name, :permissions, :seo_index, :description, :display_order, :board_group_id

        scope :visible, lambda{|user| where((user.present? && user.is_admin?) ? "" : 'permissions != "hide"')}


	def resolve_permissions
	    if permissions != "default"
		permissions
	    else
		Roxiware::Param::Param.application_param_val("blog", "blog_comment_permissions")
	    end
	end

        def new_post_count(topics_read)
            1
        end

        def post_count
            comment_count
        end

        def pending_post_count
            pending_comment_count
        end

        before_validation do
            self.comment_count = self.topics.sum(:comment_count)-self.topics.count
            self.pending_comment_count = self.topics.sum(:pending_comment_count)
	    last_topic = self.topics.select{|topic| topic.last_post.present?}.sort{|x, y| x.last_post.comment_date <=> y.last_post.comment_date}.last

            self.last_post = last_topic.last_post if last_topic.present?
	    self.seo_index = self.name.to_seo
	    if self.name_changed?
	        # if we changed the name, then we need to update the links and guids for the topics
	        self.topics.each{|topic| topic.guid = ""; topic.topic_link = ""}
	    end
        end
     end

    class Topic < ActiveRecord::Base
      include ActionView::Helpers::TextHelper
      include Roxiware::BaseModel
      self.table_name="forum_topics"
      ALLOWED_TOPIC_PERMISSIONS = %w(board open moderate closed hide)

      has_many :comments, :class_name=>"Roxiware::Comment", :dependent=>:destroy, :as=>:post
      def posts 
          self.comments
      end
      def posts=(post_items)
          self.comments = post_items
      end

      belongs_to :board, :counter_cache => :topic_count, :autosave=>true
      belongs_to :last_post, :class_name=>"Roxiware::Comment"

      has_many :term_relationships, :as=>:term_object, :class_name=>"Roxiware::Terms::TermRelationship", :dependent=>:destroy, :autosave=>true
      has_many :terms, :through=>:term_relationships, :class_name=>"Roxiware::Terms::Term"
      default_scope order("last_post_date DESC")

      validates :title, :length=>{:minimum=>1,
					:too_short => "The title must at least  %{count} characters.",
					:maximum=>255,
					:too_long => "The title can be no larger than ${count} characters."
					}

      validates_presence_of :permissions, :inclusion=> {:in => ALLOWED_TOPIC_PERMISSIONS}, :message=>"Invalid post permissions."

      edit_attr_accessible :title, :permissions, :category_name, :tag_csv, :as=>[:super, :admin, :user, nil]
      ajax_attr_accessible :title, :permissions, :tag_csv, :category_name, :last_post, :posts, :topic_link, :guid

      scope :visible, lambda{ |user| joins(:comments).where('forum_topics.permissions != "hide" AND comments.comment_status="publish"').group("forum_topics.id") unless (user.present? && user.is_admin?) }

      def root_post
	  self.posts.first
      end

      def new_post_count(last_read)
          self.comments.where("comment_date > ? AND comments.id != ?", Time.at(last_read.to_i), self.root_post.id).count
      end

      def post_count
          # don't count the first one
          comment_count-1
      end

      def pending_post_count
          pending_comment_count
      end

      def resolve_comment_permissions
	  if permissions != "board"
	      permissions
	  else
	      self.board.resolve_permissions
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
         seo_index = self.title.to_seo
         self.guid = self.topic_link = "/forum/#{self.board.seo_index}/#{self.root_post.comment_date.strftime('%Y/%-m/%-d')}/#{seo_index}" if self.root_post
	 self.last_post = self.posts.published().last
	 self.last_post_date = self.last_post.present? ? self.last_post.comment_date : self.root_post.comment_date
      end
    end
  end
end