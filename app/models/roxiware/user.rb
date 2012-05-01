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

    attr_accessible :name, :email, :password, :password_confirmation, :remember_me, :as=>"user"
    attr_accessible :username, :name, :email, :password, :password_confirmation, :remember_me, :role, :as=>"admin"

    # Activemodel, it'd be so much easier if we could actually access the names of writable attributs
    # given above in code
    def writable_attribute_names(current_user)
       case current_user.role
       when "admin"
          if current_user.id == id
             [:username, :name, :email, :password, :password_confirmation, :remember_me]
          else
             [:username, :name, :email, :password, :password_confirmation, :remember_me, :role]
          end
       when "user"
          [:name, :email, :password, :password_confirmation, :remember_me]
       else
          []
       end
    end
  end
end