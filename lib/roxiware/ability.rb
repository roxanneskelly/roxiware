module Roxiware
 class Ability
  include CanCan::Ability
  def initialize(user, params)
    puts "INITIALIZING ROXIWARE ABILITIES"
    user ||= Roxiware::User.new # guest user (not logged in)
    role = user.role
    if params.has_key?(:preview)
       role="guest"
    end
    case role
    when "super"
      can :manage, :all
      can :comment, Roxiware::Blog::Comment
      can :comment, Roxiware::Blog::Post
      can :read_comments, Roxiware::Blog::Post
      cannot :delete, Roxiware::User, :id=>user.id

    when "admin"
      can :manage, :all
      can :comment, Roxiware::Blog::Comment
      can :comment, Roxiware::Blog::Post
      cannot :delete, Roxiware::User, :id=>user.id
      cannot [:create, :update, :delete], Roxiware::User, :role=>"super"
      cannot [:create, :destroy], [Roxiware::Layout::Layout, Roxiware::Layout::PageLayout, Roxiware::Layout::LayoutSection, Roxiware::Layout::WidgetInstance, Roxiware::Layout::Widget]
      can :manage, Roxiware::Book
      can :manage, Roxiware::BookSeries
      cannot :move, Roxiware::Layout::WidgetInstance
      cannot :edit, [Roxiware::Layout::Layout, Roxiware::Layout::PageLayout, Roxiware::Layout::LayoutSection, Roxiware::Layout::WidgetInstance, Roxiware::Layout::Widget]
      cannot :manage, Roxiware::Param::Param do |param|
         param_permissions = param.param_description.permissions.split(",")
	 param_permissions.present? && (!param_permissions.include?("admin"))
      end
      cannot :manage, Roxiware::Param::ParamDescription
      can :read_comments, Roxiware::Blog::Post

    when "user"
      can :read, [Roxiware::NewsItem, Roxiware::PortfolioEntry, Roxiware::Page, Roxiware::Event, Roxiware::GalleryItem, Roxiware::Gallery, Roxiware::Service]
      can :read, Roxiware::Person
      can :manage, Roxiware::Person, :id=>user.person_id
      can :create, Roxiware::GalleryItem
      can :manage, Roxiware::GalleryItem, :person_id=>user.person.id
      can :create, Roxiware::Blog::Post
      can :manage, Roxiware::Blog::Post, :person_id=>user.person.id
      can :read, Roxiware::Blog::Post, :post_status=>"publish"
      can :read, Roxiware::Blog::Comment, :post => {:post_status=>"publish"}, :comment_status=>"publish"
      can :comment, Roxiware::Blog::Post do |post|
         (self.person_id==user.person.id) || ["open", "moderate"].include?(post.resolve_comment_permissions)
      end
      can :read_comments, Roxiware::Blog::Post do |post|
        (self.person_id==user.person.id || ["open", "moderate", "closed"].include?(post.resolve_comment_permissions))
      end
      can :manage, Roxiware::Blog::Comment, :post => {:person_id=>user.person.id}
      can :manage, Roxiware::User do |resource|
        resource==user
      end
      can :read, Roxiware::Book
      can :read, Roxiware::BookSeries
      can :read, Roxiware::Page, :page_type=>["content", "form"]
    else
      can :read, [Roxiware::NewsItem, 
                  Roxiware::PortfolioEntry, 
                  Roxiware::Page, 
                  Roxiware::Event, 
                  Roxiware::GalleryItem, 
                  Roxiware::Gallery, 
                  Roxiware::Book,
                  Roxiware::BookSeries,
                  Roxiware::Service]
      can :read, Roxiware::Person
      can :read, Roxiware::Blog::Post, :post_status=>"publish"
      can :read_comments, Roxiware::Blog::Post, :post_status=>"publish", :resolve_comment_permissions=>["open", "moderate", "closed"]

      can :read, Roxiware::Blog::Comment, :post => {:post_status=>"publish", :resolve_comment_permissions=>["open", "moderate", "closed"]}, :comment_status=>"publish"
      can :comment, Roxiware::Blog::Post do |post|
        ["open", "moderate"].include?(post.resolve_comment_permissions) && (post.post_status == "publish")
      end
      can :read_comments, Roxiware::Blog::Post do |post|
        puts "RESOLVE COMMENT PERMISSIONS " + post.resolve_comment_permissions
        (post.post_status == "publish") && ["open", "moderate", "closed"].include?(post.resolve_comment_permissions)
      end
    end
  end
 end
end
