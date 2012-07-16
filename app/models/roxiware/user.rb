module Roxiware
  class User < ActiveRecord::Base
    include Roxiware::BaseModel
    self.table_name="users"
    has_one :person, :autosave=>true, :dependent=>:destroy

    validates :username, :length=>{:minimum=>3,
                                   :too_short => "The username must be at least %{count} characters.", 
                                   :maximum=>32,
                                   :too_long => "The username must be no more than %{count} characters." 
				   }
    validates :password, :length=>{:minimum=>6,
                                   :too_short => "The password must be at least %{count} characters.", 
                                   :maximum=>64,
                                   :too_long => "The password must be no more than %{count} characters.", 
				   :allow_blank=>true}
    validates_confirmation_of :password, :message=>"The confirmation does not match the password."
    validates_uniqueness_of :email, :message=>"The email address has already been used."
    validates_presence_of   :email, :message => "An email address is required"

    validates_uniqueness_of :username, :message=>"The username has already been taken."
    validates_presence_of :role, :inclusion => {:in => %w(guest admin user)}, :message=>"Invalid role."

    validates_format_of     :email, :with  => Devise.email_regexp



    # Include default devise modules. Others available are:
    # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
    devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable

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
    ajax_attr_accessible :username, :as=>[:self]
    ajax_attr_accessible :full_name, :role, :as=>[:self, :admin, nil]
  end
end