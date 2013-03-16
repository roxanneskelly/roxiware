module Roxiware
   module Param
      module ParamClientBase
         def self.included(base)
            base.extend(ParamClientBaseClassMethods)
         end

         module ParamClientBaseClassMethods
         end
	    def get_params(param_class=:local)
	       if @params.nil?
		  @params = {}
		  params.where(:param_class=>param_class).each do |param|
		     @params[param.name.to_sym] = param.conv_value
		  end
	       end
	       @params
	    end

	    def get_param(name)
	      get_param_objs
	      @param_objs[name.to_sym]
	    end

	    def set_param(name, value, description_guid=nil, param_class=nil)
	      get_param_objs
	      return nil if (@param_objs[name.to_sym].present? && (@param_objs[name.to_sym].param_object_type == "Roxiware::Layout::WidgetInstance"))
	      if (@param_objs[name.to_sym].present?) 
	         param_class ||= @param_objs[name.to_sym].param_class
		 description_guid ||= @param_objs[name.to_sym].description_guid
	         @param_objs[name.to_sym].destroy
              end
	      param_class ||= :local
	      @param_objs[name.to_sym] = self.params.build(
		    {:param_class=> param_class,
		     :name=> name,
		     :description_guid=>description_guid,
		     :value=>value}, :as=>"")
	      @param_objs[name.to_sym]
	    end

	    def get_param_objs
	       if @param_objs.nil?
		  @param_objs = {}
		  params.each do |param|
		     @param_objs[param.name.to_sym] =  param
		  end
	       end
	       @param_objs
	    end
      end

      class Param < ActiveRecord::Base
          include Roxiware::BaseModel
	  include ParamClientBase
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

          def self.refresh_application_params
	     @application_params = {}
	  end

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

	  def self.set_application_param(application, param, description_guid, value)
	     self.application_params(application)
	     @application_params[application][param] = Param.create(
	               {:param_class=>application, 
	                :name=>param, 
			:param_object_type=>nil, 
			:description_guid=>description_guid, 
			:param_object_id=>nil,
			:value=>value}, :as=>"")  if @application_params[application][param].nil?

	     @application_params[application][param].value = value
	     @application_params[application][param].save!
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

	  def a
	     if description.field_type == "array"
	        array_params
	     else
	        #raise Exception("Invalid type")
		[]
	     end
	  end

	  def h
	     if description.field_type == "hash"
	        hash_params
	     else
	        {}
	        # raise Exception("Invalid type")
	     end
	  end

	  def array_params
	     hash_params.collect{|name, value| value}.sort_by{|param| param.name}
	  end

          def to_jstree_data
	     metadata = {}
	     metadata = Hash[params.collect{|param| [param.name, {"value"=>param.value, "guid"=>param.description_guid}]}]
	     metadata.delete("children")
	     result = { "description_guid" => self.description_guid,
                        "params"=>metadata }
	     if(self.hash_params["children"].present? && self.hash_params["children"].array_params.present?)
                 result["children"] = self.hash_params["children"].array_params.collect{|param| param.to_jstree_data}
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
             self.description_guid = xml_param["description"]

	     xml_param_description = xml_param.find_first("param_description")
             if xml_param_description.present?
	        self.description_guid = xml_param_description["guid"]
	        if include_description && xml_param_description.content.present?
                   self.build_param_description if self.param_description.blank?
		   self.param_description.import(xml_param_description)
                end
	     end

             self.param_description = Roxiware::Param::ParamDescription.where(:guid=>self.description_guid).first

	     if(self.param_description.blank?)
	        puts "param description #{self.description_guid} for #{self.name} not found"
	     end

             param_value = xml_param.find_first("value")
	     param_value = xml_param if param_value.blank?

	     case self.param_description.field_type
	        when "hash"
		  param_value.find("param").each do |xml_hashparam|
		     new_param = Param.new
		     new_param.import(xml_hashparam, include_description)
		     params << new_param
		  end
		when "array"
		  param_value.find("param").each do |xml_arrayparam|
		     new_param = Param.new
		     new_param.import(xml_arrayparam, include_description)
		     params << new_param
		  end
		else
	          self.value = param_value.content
	     end
	  end

          def export(xml_params, include_description)
	     if (self.param_description.field_type == "hash") || (self.param_description.field_type == "array") 
	        xml_params.param(:class=>self.param_class, :name=>self.name, :description=>self.description_guid) do |xml_param|
                    self.params.each do |param|
		        param.export(xml_param, include_description)
		    end
                 end
             else
	         xml_params.param(self.value, :class=>self.param_class, :name=>self.name, :description=>self.description_guid)
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
	attr_accessible :meta         # Meta information for controls (select values, etc.)
	attr_accessible :permissions  # permissions for parameter

	  def import(xml_param_description)
	     self.guid = xml_param_description["guid"]
	     self.name = xml_param_description.find_first("name").content
	     self.description = xml_param_description.find_first("description").content
	     self.field_type = xml_param_description.find_first("field_type").content
	     self.permissions = xml_param_description.find_first("permissions").content
	     self.meta = xml_param_description.find_first("meta").content
	     puts "Importing description #{self.guid} : #{self.name}" 
	     self.save!
	  end

          def export(xml_param_descriptions)
	     xml_param_descriptions.param_description(:guid=>self.guid) do |xml_param_description|
  	       xml_param_description.name         self.name
	       xml_param_description.description  self.description
  	       xml_param_description.field_type   self.field_type
	       xml_param_description.permissions  self.permissions
	       xml_param_description.meta         self.meta
	     end
          end
      end
   end
end
