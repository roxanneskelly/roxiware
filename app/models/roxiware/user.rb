module Roxiware
  class User < ActiveRecord::Base
    set_table_name "users"
    validates_presence_of :username
    validates_uniqueness_of :username
    validates_presence_of :role, :inclusion => {:in => %w(guest admin user)}

    # Include default devise modules. Others available are:
    # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
    devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable


    # Setup accessible (or protected) attributes for your model

    attr_accessible :username, :name, :email, :password, :password_confirmation, :remember_me, :as=>nil # nil represents 'system'
    attr_accessible :name, :email, :password, :password_confirmation, :remember_me, :as=>"user"
    attr_accessible :username, :name, :email, :password, :password_confirmation, :remember_me, :role, :as=>"admin"

    # Activemodel, it'd be so much easier if we could actually access the names of writable attributs
    # given above in code
    def writeable_attribute_names(current_user)
       role = nil
       if current_user.id == id
         role = "self"
       else
         role=current_user.role unless current_user.nil?
       end
       case role
       when "self"
           [:username, :name, :email, :password, :password_confirmation, :remember_me]
       when "admin"
           [:username, :name, :email, :password, :password_confirmation, :remember_me, :role]
       when "user"
          [:name, :email, :password, :password_confirmation, :remember_me]
       else
          []
       end
    end
  end
end