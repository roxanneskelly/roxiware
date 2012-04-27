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

    def role
       read_attribute(:role)
    end

    def role=(role_name)
      write_attribute(:role, role_name)
    end
    # Setup accessible (or protected) attributes for your model
    attr_accessible :username, :name, :email, :password, :password_confirmation, :remember_me, :role
  end
end