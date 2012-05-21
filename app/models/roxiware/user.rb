module Roxiware
  class User < ActiveRecord::Base
    include Roxiware::BaseModel
    self.table_name="users"
    has_one :person, :autosave=>true, :dependent=>:destroy

    validates_presence_of :username
    validates_uniqueness_of :username
    validates_presence_of :role, :inclusion => {:in => %w(guest admin user)}

    # Include default devise modules. Others available are:
    # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
    devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

    def first_name
      self.person.first_name unless self.person.nil?
    end

    def first_name=(name)
      self.person.first_name=name unless self.person.nil?
    end

    def last_name
      self.person.last_name unless self.person.nil?
    end
 
    def last_name=(name)
      self.person.last_name=name unless self.person.nil?
    end
 
    def full_name
       self.person.full_name unless self.person.nil?
    end    

    # Setup accessible (or protected) attributes for your model

    edit_attr_accessible :email, :password, :password_confirmation, :remember_me, :person_id, :first_name, :last_name, :as=>[:admin, :self, nil]
    edit_attr_accessible :username, :role, :as=>[:admin, nil]
    ajax_attr_accessible :username, :role, :as=>[:self]
    ajax_attr_accessible :full_name, :as=>[:self, :admin, nil]
  end
end