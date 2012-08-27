require 'devise'
require 'acts_as_tree_rails3'
module Roxiware::Terms
  class TermRelationship < ActiveRecord::Base
    include Roxiware::BaseModel
    self.table_name = "term_relationships"
    belongs_to :term_object, :polymorphic=>true
    belongs_to :term
  end

  class Term < ActiveRecord::Base
    include Roxiware::BaseModel
    self.table_name = "terms"

    belongs_to :term_taxonomy
    has_many :term_relationships, :dependent=>:destroy

    acts_as_tree :foreign_key => "parent_id"

    validates_presence_of :term_taxonomy_id, :null=>false
    validates_presence_of :name, :null=>false
    validates_presence_of :seo_index, :null=>false
    validates_uniqueness_of :seo_index, :scope=>:term_taxonomy_id

    edit_attr_accessible :name, :seo_index, :term_taxonomy_id, :as=>[nil]
    ajax_attr_accessible :name, :seo_index, :term_taxonomy_id, :as=>[:admin, :user, :guest]

    @@categories = nil

    def self.get_or_create(term_strings, term_taxonomy_id)
       term_string_set = Set.new(term_strings)
       term_str_hash = Hash[term_string_set.collect{|str| [str.to_seo, str]}]
       current_terms = self.where(:term_taxonomy_id=>term_taxonomy_id, :seo_index=>term_str_hash.keys)
       current_terms.each {|term| term_str_hash.delete(term.seo_index)}
       term_str_hash.each do |seo_index, name|
          current_terms << Term.create({:name=>name, :term_taxonomy_id=>term_taxonomy_id}, :as=>"")
       end
       current_terms
    end

    before_validation() do 
       self.seo_index = self.name.to_seo
    end

    def self.categories
       @@categories ||= Hash[Term.where(:term_taxonomy_id=>TermTaxonomy::CATEGORY_ID).map {|category| [category.id, category]  }]
       print "GOT CATEGORIES " + @@categories.inspect
       @@categories
    end
  end


  class TermTaxonomy < ActiveRecord::Base
    include Roxiware::BaseModel
    self.table_name = "term_taxonomies"

    CATEGORY_ID = 1
    TAG_ID = 2

    has_many :terms, :dependent=>:destroy

    validates_uniqueness_of :seo_index
    edit_attr_accessible :name, :seo_index, :description, :as=>[:admin, nil]
    ajax_attr_accessible :name, :seo_index, :description, :as=>[:user, :guest]


    before_validation() do 
       self.seo_index = self.name.downcase.gsub(/[^a-z0-9]+/i, '-')
    end
  end
end
