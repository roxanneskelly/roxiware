class Ability
  include CanCan::Ability
  def initialize(user)
    user ||= Roxiware::User.new # guest user (not logged in)
    print "role is " + user.role + "\n"
    case user.role
    when "admin"
      can :manage, :all
    when "user"
      can :read, [Roxiware::NewsItem, Roxiware::PortfolioEntry, Roxiware::Page, Roxiware::Event, Roxiware::GalleryItem, Roxiware::Gallery, Roxiware::Service]
      can :read, Roxiware::Person, :show_in_directory=>true
      can :manage, Roxiware::Person, :id=>user.person_id
      can :create, Roxiware::GalleryItem
      can :manage, Roxiware::GalleryItem, :person_id=>user.person.id

      can :manage, Roxiware::User do |resource|
        resource==user
      end
    else
      can :read, [Roxiware::NewsItem, 
                  Roxiware::PortfolioEntry, 
                  Roxiware::Page, 
                  Roxiware::Event, 
                  Roxiware::GalleryItem, 
                  Roxiware::Gallery, 
                  Roxiware::Service]

      can :read, Roxiware::Person, :show_in_directory=>true
    end
  end
end
