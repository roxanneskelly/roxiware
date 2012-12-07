module Roxiware
   module Param
     # Layout
     # overall layout
      class Param < ActiveRecord::Base
          include Roxiware::BaseModel
          self.table_name= "params"

	  
	  has_many   :params, :class_name=>"Roxiware::Param::Param", :as=>:param_object, :autosave=>true, :dependent=>:destroy
	  belongs_to :param_object, :polymorphic=>true

	  attr_accessible :param_class        # type of the param (style, local, global)
	  attr_accessible :name               # name of the param
	  attr_accessible :value              # value of the param
	  attr_accessible :widget_instance_id # parent widget instance
	  belongs_to :param_description, :autosave=>true, :foreign_key=>:description_guid, :primary_key=>:guid

          edit_attr_accessible :param_class, :name, :param_object_type, :description_guid, :object_id, :as=>[nil]
	  edit_attr_accessible :value, :as=>[:super, :admin, nil]
	  ajax_attr_accessible :param_class, :name, :param_object_type, :description_guid, :object_id, :as=>[:super, :admin]


	  def self.application_params(application)
	     @application_params ||= {}
	     @application_params[application] ||= Hash[self.where(:param_class=>application).collect(){|param| [param.name, param]}]
	     @application_params[application].values
	  end

	  def self.application_param_val(application, param)
	     self.application_params(application)
	     result = @application_params[application][param].conv_value if  @application_params[application][param].present?
	     result
	  end

	  def self.refresh_application_params
	     @application_params = {}
	  end

	  def description
	     @description ||= param_description || create_param_description({:guid=>self.description_guid})
	     @description
	  end

	  def hash_params
	     @hash_params ||= Hash[params.collect{|param| [param.name, param]}]
	  end

	  def array_params
	     hash_params.collect{|name, value| value}.sort_by{|param| param.name}
	  end

          def to_jstree_data(title_param)
	     metadata = {}
	     print "to_jstree_data for #{title_param}\n"
	     print self.hash_params.inspect + "\n\n"
	     metadata = Hash[params.collect{|param| [param.name, {"value"=>param.value, "guid"=>param.description_guid}]}]
	     metadata.delete("children")
	     result = { "description_guid" => self.description_guid,
                        "params"=>metadata }
	     if(self.hash_params["children"].present? && self.hash_params["children"].array_params.present?)
                 result["children"] = self.hash_params["children"].array_params.collect{|param| param.to_jstree_data(title_param)}
	     end
             return result
          end

	  def to_s
	    conv_value.to_s
	  end

	  def conv_value
	     case description.field_type
	       when "array"
	         array_params
	       when "hash"
	         hash_params
	       when "integer"
	         value.to_i
	       when "string"
	         value.to_s
	       when "float"
	         value.to_f
	       when "bool"
	         return (value == "true")
	       when "asset"
	         return value
	       else
	         return value
	     end
	  end
	  

	  def import(xml_param, include_description)
	     self.param_class = xml_param["class"]
	     self.name = xml_param["name"]
	     xml_param_description = xml_param.find_first("param_description")
             if xml_param_description.present?
	     print "description guid #{self.name}\n"
	       self.description_guid = xml_param_description["guid"]
	       if include_description && xml_param_description.content.present?
                   self.build_param_description if self.param_description.blank?
		   self.param_description.import(xml_param_description)
	       else
	           self.param_description = Roxiware::Param::ParamDescription.where(:guid=>self.description_guid).first
	       end
	     end
	     print "description guid #{self.description_guid}\n"
	     case self.param_description.field_type
	        when "hash"
		  xml_param.find_first("value").find("param").each do |xml_hashparam|
		     new_param = Param.new
		     new_param.import(xml_hashparam, include_description)
		     params << new_param
		  end
		when "array"
		  xml_param.find_first("value").find("param").each do |xml_arrayparam|
		     new_param = Param.new
		     new_param.import(xml_arrayparam, include_description)
		     params << new_param
		  end
		else
	          self.value = xml_param.find_first("value").content
	     end
	  end

          def export(xml_params, include_description)
	     xml_params.param(:class=>self.param_class, :name=>self.name) do |xml_param|
	       case self.param_description.field_type
	         when "hash"
		   xml_param.value do |xml_hashvalue|
		      self.params.each do |hash_param|
		         hash_param.export(xml_hashvalue, include_description)
		      end
		   end
		 when "array"
		   xml_param.value do |xml_arrayvalue|
		      self.params.each do |array_param|
		         array_param.export(xml_arrayvalue, include_description)
		      end
		   end
		 else
	          xml_param.value  self.value
	       end
	       if include_description
		   self.description.export(xml_param)
	       else
	           xml_param.param_description(:guid=>self.description_guid)
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
	     self.save!
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
