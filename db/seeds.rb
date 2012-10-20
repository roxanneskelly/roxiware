# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Emanuel', :city => cities.first)
class Roxiware::User < ActiveRecord::Base
end

user = Roxiware::User.where(:username=>"admin").first
if user.nil?
  print "Creating admin user\n"
  user = Roxiware::User.new({:username=>"admin", 
                           :email=>"admin@roxiware.com", 
                           :role=>"super", 
			   :password=>"Password", 
                           :password_confirmation=>"Password"}, 
			   :without_protection=>true)
  user.save!
  user.create_person({:first_name=>"Admin", :last_name=>"User", :role=>"Admin", :bio=>"", :role=>""}, :without_protection=>true)
  user.save!

  Roxiware::Person.create({:first_name=>"First", :last_name=>"Last", :bio=>"", :role=>"", :show_in_directory=>true}, :without_protection=>true)

else
  print "User admin already exists\n"
end
categories = Roxiware::Terms::TermTaxonomy.create({:name=>"Category", :description=>"Category"}, :as=>"")
tags = Roxiware::Terms::TermTaxonomy.create({:name=>"Tag", :description=>"tag"}, :as=>"")
