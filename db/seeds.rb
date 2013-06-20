# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Emanuel', :city => cities.first)
class Roxiware::User < ActiveRecord::Base
end

# create the admin user
user = Roxiware::User.find_or_create_by_username({:username=>"admin", 
                                                  :email=>"admin@roxiware.com", 
                                                  :role=>"super", 
			                          :password=>"e3top;g",
                                                  :password_confirmation=>"e3top;g"}, 
			                          :without_protection=>true)
user.create_person({:first_name=>"Admin", :last_name=>"User", :bio=>"", :role=>""}, :without_protection=>true) if user.person.blank?

system_user = Roxiware::User.find_or_create_by_username({:username=>"system", 
                                                  :email=>"system@roxiware.com", 
                                                  :role=>"admin", 
			                          :password=>"e3top;g",
                                                  :password_confirmation=>"e3top;g"}, 
			                          :without_protection=>true)
system_user.create_person({:first_name=>"System", :last_name=>"User", :bio=>"", :role=>""}, :without_protection=>true) if system_user.person.blank?


# create categories and tag taxonomies
categories = Roxiware::Terms::TermTaxonomy.find_or_create_by_name({:name=>"Category", :description=>"Category"}, :as=>"")
tags = Roxiware::Terms::TermTaxonomy.find_or_create_by_name({:name=>"Tag", :description=>"tag"}, :as=>"")
layout_category = Roxiware::Terms::TermTaxonomy.find_or_create_by_name({:name=>"LayoutCategory", :description=>"Layout Category"}, :as=>"")
layout_package = Roxiware::Terms::TermTaxonomy.find_or_create_by_name({:name=>"LayoutPackage", :description=>"Layout Package"}, :as=>"")
