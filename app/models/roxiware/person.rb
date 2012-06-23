require 'set'
class Roxiware::Person < ActiveRecord::Base
   include Roxiware::BaseModel
   self.table_name=  "people"

   belongs_to :user, :polymorphic=>true
   has_many :social_networks, :autosave=>true, :dependent=>:destroy
   validates_presence_of :first_name
   validates :first_name, :length=>{:minimum=>2}
   validates_uniqueness_of :first_name, :scope=>:last_name
   validates_uniqueness_of :seo_index, :message=>"Name not sufficiently unique"

   edit_attr_accessible :first_name, :last_name, :show_in_directory, :role, :email, :image_url, :thumbnail_url, :bio, :as=>[:admin, :self, nil]
   ajax_attr_accessible :first_name, :last_name, :role, :email, :image_url, :bio, :show_in_directory

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
	  logger.debug("setting #{arg} to #{value}")
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
	print "sending for #{arg}\n"
	self.send(:edit_attr_accessible, arg, :as=>options[:as]) 
      end
   end

   add_social_networks :twitter, :website, :facebook, :google, :as=>[:admin, :self, nil]


   def full_name
      return_full_name = self.first_name || ""
      return_full_name = (return_full_name + " "+ self.last_name) unless self.last_name.blank?
      return_full_name
   end

    after_validation do
       self.seo_index = self.full_name.downcase.gsub(/[^a-z0-9]+/i, '-')
    end
end
