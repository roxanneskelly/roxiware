module Roxiware
  class BaseModel < ActiveRecord::Base
    include ActiveModel::MassAssignmentSecurity::ClassMethods

    def assign_attributes(values, options = {})
     sanitize_for_mass_assignment(values, options[:as]).each do |k, v|
       send("#{k}=", v)
     end
    end
  end
end