class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
    case user.role
    when "admin"
       can :manage, :all
    when "user"
       can :read, :all

       can :update, User do |resource|
         resource==user
       end
    else
       can :read, [NewsItem]
    end
  end
end
