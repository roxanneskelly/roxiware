require 'uri'
class Roxiware::Person < ActiveRecord::Base
   include Roxiware::BaseModel
   include ActionView::Helpers::AssetTagHelper
   self.table_name=  "people"


   self.default_image = "unknown_person"

   belongs_to :user, :polymorphic=>true
   has_many :social_networks, :autosave=>true, :dependent=>:destroy

   validates :first_name, :length=>{:minimum=>3,
                                   :too_short => "The first name must be at least %{count} characters.", 
                                   :maximum=>32,
                                   :too_long => "The first name must be no more than %{count} characters." 
				   }
    validates_uniqueness_of :seo_index, :message=>"The name has already been taken."

    validates :email, :length=>{:maximum=>256,
                                 :too_long => "The email address must be no more than %{count} characters." 
				 }
    validates_uniqueness_of :email, :message=>"The email address has is not unique."

    validates :role, :length=>{:maximum=>64,
                                 :too_long => "The role must be no more than %{count} characters." 
				 }

    validates :image_thumbprint, :length=>{:maximum=>64,
                                 :too_long => "The image thumbprint must be no more than %{count} characters." 
				 }

    validates :bio, :length=>{:maximum=>32768,
                                 :too_long => "The bio must be no more than %{count} characters." 
				 }

   edit_attr_accessible :first_name, :last_name, :show_in_directory, :role, :email, :image_thumbprint, :bio, :as=>[:admin, :self, nil]
   ajax_attr_accessible :first_name, :last_name, :role, :email, :image_thumbprint, :bio, :show_in_directory, :full_name, :seo_index

   define_upload_image_methods

   def self.add_social_networks (*args)
      options = {}
      if args.last.class == Hash
        options = args.pop
      end
      options[:as] ||=  []
      if options[:as].class != Array
        options[:as] = [options[:as]]
      end
      args.each do |arg|
        self.send(:define_method, "#{arg}=") do |value|
          social_net_entry = self.social_networks.find_by_network_type("#{arg}")
	  if (value.nil? || value.blank?)
	     logger.debug("deleting social network")
	     self.social_networks.delete(social_net_entry) unless social_net_entry.nil?
	  else
             logger.debug("updating attributes")
	     if social_net_entry    
               social_net_entry.update_attributes({:network_link=>value})
             else
	       self.social_networks.create({:network_type=>"#{arg}", :network_link=>value})
	     end
	  end
	end
        self.send(:define_method, "#{arg}") do
	  social_net = self.social_networks.find_by_network_type("#{arg}")
	  social_net.network_link if social_net
	end
	self.send(:edit_attr_accessible, arg, :as=>options[:as]) 
      end
   end

   add_social_networks :twitter, :website, :facebook, :google, :as=>[:admin, :self, nil]

   def full_name
      return_full_name = self.first_name || ""
      return_full_name = (return_full_name + " "+ self.last_name) unless self.last_name.blank?
      return_full_name
   end

    before_validation do
       self.seo_index = self.full_name.to_seo
    end
end
