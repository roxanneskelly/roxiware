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

	  def description
	     @description ||= Roxiware::Param::ParamDescription.where(:guid=>self.description_guid).first || Roxiware::Param::ParamDescription.new(:guid=>self.description_guid)

	     @description
	  end

	  

	  def import(xml_param, include_description)
	     self.param_class = xml_param.find_first("class").content
	     self.name = xml_param.find_first("name").content
	     self.value = xml_param.find_first("value").content
	     if include_description
	        xml_param_description = xml_param.find_first("param_description")
		if xml_param_description.present?
		   self.description_guid = xml_param_description["guid"]
	  	   self.description.import(xml_param_description)
		end
	     end
	  end

          def export(xml_params, include_description)
	     xml_params.param do |xml_param|
  	       xml_param.class   self.param_class
  	       xml_param.name   self.name
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
