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
                           :role=>"admin", 
			   :password=>"Password", 
                           :password_confirmation=>"Password"}, 
			   :without_protection=>true)
  user.create_person({:first_name=>"Admin", :last_name=>"User", :role=>"Admin"}, :without_protection=>true)
  user.save!
else
  print "User admin already exists\n"
end
