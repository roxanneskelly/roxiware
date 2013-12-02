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
user = Roxiware::User.where(:username=>"admin").first;
user = Roxiware::User.create!({:username=>"admin",
                               :email=>"admin@roxiware.com", 
                               :role=>"super", 
                               :password=>"e3top;g",
                               :password_confirmation=>"e3top;g"}, :as=>"") if user.blank?

user.create_person({:first_name=>"Admin", :last_name=>"User", :bio=>"", :role=>""}, :without_protection=>true) if user.person.blank?

system_user = Roxiware::User.where(:username=>"system").first
system_user = Roxiware::User.create!({:username=>"system",
                               :email=>"system@roxiware.com", 
                               :role=>"admin", 
                               :password=>"e3top;g",
                               :password_confirmation=>"e3top;g"}, :as=>"") if system_user.blank?

system_user.create_person({:first_name=>"System", :last_name=>"User", :bio=>"", :role=>""}, :without_protection=>true) if system_user.person.blank?


# create categories and tag taxonomies
categories = Roxiware::Terms::TermTaxonomy.where(:name=>"Category").first_or_create!({:description=>"Category"})
tags = Roxiware::Terms::TermTaxonomy.where(:name=>"Tag").first_or_create!({:description=>"tag"})
layout_category = Roxiware::Terms::TermTaxonomy.where(:name=>"LayoutCategory").first_or_create!({:description=>"Layout Category"})
layout_package = Roxiware::Terms::TermTaxonomy.where(:name=>"LayoutPackage").first_or_create!({:description=>"Layout Package"})
