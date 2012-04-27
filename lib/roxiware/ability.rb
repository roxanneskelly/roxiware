
class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= Roxiware::User.new # guest user (not logged in)
    case user.role
    when "admin"
      can :manage, :all
    when "user"
      can :read, :all

      can :update, Roxiware::User do |resource|
        resource==user
      end
    else
      can :read, [Roxiware::NewsItem]
    end
  end
end
