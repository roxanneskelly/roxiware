module Roxiware
   module Param
     # Layout
     # overall layout
      class Param < ActiveRecord::Base
          include Roxiware::BaseModel
          self.table_name= "params"

	  belongs_to :param_object, :polymorphic=>true

	  attr_accessible :param_class        # type of the param (style, local, global)
	  attr_accessible :name               # name of the param
	  attr_accessible :value              # value of the param
	  attr_accessible :widget_instance_id # parent widget instance
	  belongs_to :param_description, :autosave=>true, :foreign_key=>:description_guid, :primary_key=>:guid

	  scope :settings, where(:param_class=>"setting")

          edit_attr_accessible :param_class, :name, :param_object_type, :description_guid, :object_id, :as=>[nil]
	  edit_attr_accessible :value, :as=>[:admin, nil]
	  ajax_attr_accessible :param_class, :name, :param_object_type, :description_guid, :object_id, :as=>[:admin]

	  def description
	     @description ||= Roxiware::Param::ParamDescription.where(:guid=>self.description_guid).first || Roxiware::Param::ParamDescription.new(:guid=>self.description_guid)

	     @description
	  end

	  def conv_value
	     case description.field_type
	       when "integer"
	         value.to_i
	       when "string"
	         value.to_s
	       when "float"
	         value.to_f
	       else
	         return value
	     end
	  end
	  

	  def import(xml_param, include_description)
	     self.param_class = xml_param["class"]
	     self.name = xml_param["name"]
	     self.value = xml_param.find_first("value").content
	     if include_description
	        xml_param_description = xml_param.find_first("param_description")
		if xml_param_description.present?
		   self.description_guid = xml_param_description["guid"]
		   if self.param_description.blank?
		      self.build_param_description
		   end
	  	   self.param_description.import(xml_param_description)
		end
	     end
	  end

          def export(xml_params, include_description)
	     xml_params.param(:class=>self.param_class, :name=>self.name) do |xml_param|
	       xml_param.value  self.value
	       if include_description
		   self.description.export(xml_param)
	       end
	     end
          end
      end

      class ParamDescription < ActiveRecord::Base
        include Roxiware::BaseModel
        self.table_name= "param_descriptions"


        attr_accessible :name         # human readable name of parameter
	attr_accessible :guid         # unique id of parameter
	attr_accessible :description  # description of parameter
	attr_accessible :field_type   # type of field
	attr_accessible :permissions  # permissions for parameter

	  def import(xml_param_description)
	     self.guid = xml_param_description["guid"]
	     self.name = xml_param_description.find_first("name").content
	     self.description = xml_param_description.find_first("description").content
	     self.field_type = xml_param_description.find_first("field_type").content
	     self.permissions = xml_param_description.find_first("permissions").content
	  end

          def export(xml_param_descriptions)
	     xml_param_descriptions.param_description(:guid=>self.guid) do |xml_param_description|
  	       xml_param_description.name         self.name
	       xml_param_description.description  self.description
  	       xml_param_description.field_type   self.field_type
	       xml_param_description.permissions  self.permissions
	     end
          end
      end
   end
end
