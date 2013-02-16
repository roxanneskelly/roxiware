class Ability
  include CanCan::Ability
  def initialize(user, params)
    user ||= Roxiware::User.new # guest user (not logged in)
    role = user.role
    if params.has_key?(:preview)
       role="guest"
    end
    case role
    when "super"
      can :manage, :all
      can :comment, Roxiware::Blog::Comment
      cannot :delete, Roxiware::User, :id=>user.id

    when "admin"
      can :manage, :all
      can :comment, Roxiware::Blog::Comment
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

    when "user"
      can :read, [Roxiware::NewsItem, Roxiware::PortfolioEntry, Roxiware::Page, Roxiware::Event, Roxiware::GalleryItem, Roxiware::Gallery, Roxiware::Service]
      can :read, Roxiware::Person, :show_in_directory=>true
      can :manage, Roxiware::Person, :id=>user.person_id
      can :create, Roxiware::GalleryItem
      can :manage, Roxiware::GalleryItem, :person_id=>user.person.id
      can :create, Roxiware::Blog::Post
      can :manage, Roxiware::Blog::Post, :person_id=>user.person.id
      can :read, Roxiware::Blog::Post, :post_status=>"publish"
      can :read, Roxiware::Blog::Comment, :post => {:post_status=>"publish"}, :comment_status=>"publish"
      can :comment, Roxiware::Blog::Post do |post|
        Roxiware.blog_allow_comments && ["open", "moderate"].include?(post.comment_permissions)
      end
      can :read_comments, Roxiware::Blog::Post do |post|
        Roxiware.blog_allow_comments && (self.person_id==user.person.id || ["open", "moderate"].include?(post.comment_permissions))
      end
      can :manage, Roxiware::Blog::Comment, :post => {:person_id=>user.person.id}
      can :manage, Roxiware::User do |resource|
        resource==user
      end
      can :read, Roxiware::Book
      can :read, Roxiware::BookSeries
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
      can :read, Roxiware::Person, :show_in_directory=>true
      can :read, Roxiware::Blog::Post, :post_status=>"publish"
      can :read_comments, Roxiware::Blog::Post, :post_status=>"publish", :comment_permissions=>["open", "moderate", "closed"]

      can :read, Roxiware::Blog::Comment, :post => {:post_status=>"publish", :comment_permissions=>["open", "moderate", "closed"]}, :comment_status=>"publish"
      can :comment, Roxiware::Blog::Post do |post|
        Roxiware.blog_allow_comments && Roxiware.blog_allow_anonymous_comments && ["open", "moderate"].include?(post.comment_permissions) && (post.post_status == "publish")
      end
      can :read_comments, Roxiware::Blog::Post do |post|
        Roxiware.blog_allow_comments && (post.post_status == "publish") && ["open", "moderate", "closed"].include?(post.comment_permissions)
      end
    end
  end
end
