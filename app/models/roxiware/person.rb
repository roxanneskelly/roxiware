require 'uri'
class Roxiware::Person < ActiveRecord::Base
   include Roxiware::BaseModel
   include Roxiware::Param::ParamClientBase
   include ActionView::Helpers::AssetTagHelper
   self.table_name=  "people"
   SOCIAL_NETWORKS = %w(twitter facebook google youtube pinterest)


   self.default_image = "unknown_person"

   belongs_to :user
   has_many :params, :class_name=>"Roxiware::Param::Param", :as=>:param_object, :autosave=>true, :dependent=>:destroy
   has_many :books
   belongs_to :books
   has_one :goodreads_id_join, :as=>:grent, :autosave=>true, :dependent=>:destroy


   validates :first_name, :length=>{:minimum=>2,
                                   :too_short => "The first name must be at least %{count} characters.", 
                                   :maximum=>32,
                                   :too_long => "The first name must be no more than %{count} characters." 
				   }

   validates :first_name, :length=>{
                                   :maximum=>32,
                                   :too_long => "The middle name must be no more than %{count} characters." 
				   }

    validates_uniqueness_of :seo_index, :message=>"The name has already been taken."

    validates :email, :length=>{:maximum=>256,
                                 :too_long => "The email address must be no more than %{count} characters." 
				 }

    validates :role, :length=>{:maximum=>64,
                                 :too_long => "The role must be no more than %{count} characters." 
				 }

    validates :image_thumbprint, :length=>{:maximum=>64,
                                 :too_long => "The image thumbprint must be no more than %{count} characters." 
				 }

    validates :bio, :length=>{:maximum=>32768,
                                 :too_long => "The bio must be no more than %{count} characters." 
				 }

   edit_attr_accessible :first_name, :middle_name, :last_name, :show_in_directory, :role, :email, :image, :thumbnail, :large_image, :bio, :full_name, :goodreads_id, :as=>[:super, :admin, :self, nil]
   ajax_attr_accessible :first_name, :middle_name, :last_name, :role, :email, :image, :thumbnail, :large_image, :bio, :show_in_directory, :full_name, :seo_index, :goodreads_id

   before_destroy :destroy_images

   def goodreads_id
      self.goodreads_id_join.goodreads_id if self.goodreads_id_join.present?
   end

   def goodreads_id=(gr_id)
      if self.goodreads_id_join.blank?
         self.goodreads_id_join = Roxiware::GoodreadsIdJoin.new
      end
      self.goodreads_id_join.goodreads_id = gr_id
   end


   def full_name
      return_full_name = self.first_name || ""
      return_full_name = (return_full_name + " "+ self.middle_name) unless self.middle_name.blank?
      return_full_name = (return_full_name + " "+ self.last_name) unless self.last_name.blank?
      return_full_name
   end
   def full_name=(name)
       split_name = name.split(" ")
       self.first_name = split_name.shift
       self.last_name = split_name.pop if(split_name.present?)
       self.middle_name = split_name.join(" ")
   end

   before_validation do
       if(self.seo_index != self.full_name.to_seo)
           # if we've changed the full name, so we need to validate we didn't
           # change it to something that's already there.  If so, create
           # a new seo index with a number after it
           self.seo_index = self.full_name.to_seo
           index = 1
           while Roxiware::Person.find_by_seo_index(self.seo_index).present?
               self.seo_index = "#{self.full_name.to_seo}-#{index}"
               index += 1
           end
       end
       self.bio = Sanitize.clean(self.bio, Roxiware::Sanitizer::BASIC_SANITIZER)
       if(self.large_image.present?)
           image_uri = URI(self.large_image)
           if(!image_uri.host)
               base_file = Pathname.new(image_uri.path).basename
               extension = base_file.extname
               base_file_name = base_file.basename(".*")
               self.image = "/asset/#{base_file_name}_200x225#{extension}"
               self.thumbnail = "/asset/#{base_file_name}_50x50#{extension}"
           end
       end
    end
end
