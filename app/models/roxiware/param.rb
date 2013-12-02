module Roxiware
   module Param
      module ParamClientBase
         def self.included(base)
            base.extend(ParamClientBaseClassMethods)
         end

         module ParamClientBaseClassMethods
         end
	    def get_params(param_class=:local)
	       Hash[get_param_objs.select{|name, param_obj| param_obj.param_class == param_class}.collect{|param_pair| [param_pair[0].to_sym, param_pair[1].conv_value]}]
	    end

	    def get_by_path(path)
	       return self if path.blank?
	       path_components = path.split("/", 2)

	       param = self.get_param(path_components.shift)
	       if(param.blank?)
		   raise Exception.new("param_by_path: Param not found #{path}")
	       end
	       param.get_by_path(path_components.shift)
	    end

	    def get_param(name)
	      get_param_objs
	      @param_objs[name.to_sym]
	    end

	    def set_param(name, value, description_guid=nil, param_class=nil)

	      # refresh the params cache if needed
	      get_param_objs

	      if (@param_objs[name.to_sym].present?) 
	         # if the param is already in the cache, update the class and 
                 # description if they're not specified
	         param_class ||= @param_objs[name.to_sym].param_class
		 description_guid ||= @param_objs[name.to_sym].description_guid
		 
		 # delete the param from the cache
                 self.params.delete(@param_objs[name.to_sym]) if (self == @param_objs[name.to_sym].param_object)
		 @param_objs.delete(name.to_sym)
              end


	      raise Exception.new("Missing param description for #{name}") if description_guid.blank?
	      raise Exception.new("Missing param class for #{name}") if param_class.blank?

	      if(value.class == Roxiware::Param::Param)
	         # if the value is a param just add it
		 self.params << value
		 self.save!
		 @param_objs[name.to_sym] = value
		 return value
              end


	      # look up the param description
              param_description = Roxiware::Param::ParamDescription.find_description(description_guid)
	      raise Exception.new("Couldn't find param description #{description_guid}") if param_description.blank?
	      
	      # create an object
	      @param_objs[name.to_sym] = self.params.build(
		    {:param_class=> param_class,
		     :name=> name,
		     :description_guid=>description_guid}, :as=>"")              

	      # set the value
	      case param_description.field_type
	        when "hash"
		  @param_objs[name.to_sym].params = value.values
		when "array"
		  @param_objs[name.to_sym].params = value
		when "text"
		  @param_objs[name.to_sym].textvalue = value
		else
		  @param_objs[name.to_sym].value = value
	      end
	      @param_objs[name.to_sym].save!

	      @param_objs[name.to_sym]
	    end

	    def get_param_objs
	       @param_objs ||= Hash[self.params.collect{|param| [param.name.to_sym, param]}]
	       @param_objs
	    end

	    def get_param_obj_list
	        get_param_objs.keys.sort{|x, y| x <=> y}.collect{|key| @param_objs[key]}
	    end
      end

      class Param < ActiveRecord::Base
          include Roxiware::BaseModel
	  include ParamClientBase
          self.table_name= "params"

          PRELOAD_APPLICATION_PARAMS = %w(system blog events books events people setup custom_settings)

	  has_many   :params, :class_name=>"Roxiware::Param::Param", :as=>:param_object, :autosave=>true, :dependent=>:destroy
	  belongs_to :param_object, :polymorphic=>true

	  attr_accessible :param_class        # type of the param (style, local, global)
	  attr_accessible :name               # name of the param
	  attr_accessible :value              # value of the param
	  attr_accessible :textvalue              # large value of the param
	  attr_accessible :widget_instance_id # parent widget instance

          edit_attr_accessible :param_class, :name, :param_object_type, :description_guid, :param_object_id, :as=>[nil]
	  edit_attr_accessible :value, :as=>[:super, :admin, nil]
	  edit_attr_accessible :textvalue, :as=>[:super, :admin, nil]
	  ajax_attr_accessible :param_class, :name, :param_object_type, :description_guid, :param_object_id, :as=>[:super, :admin]


          def param_description
	      Roxiware::Param::ParamDescription.find_description(description_guid)
	  end


	  def deep_dup
	      new_param = dup
	      new_param.params = params.collect{|p| p.deep_dup}
	      new_param
	  end

          def self.refresh_application_params
	     @application_params = {}
	  end

	  def self.application_params(application)
             if @application_params.blank?
                 @application_params = {}
                 self.where(:param_class=>PRELOAD_APPLICATION_PARAMS).each do |param|
                     @application_params[param.param_class] ||= {}
                     @application_params[param.param_class][param.name] = param
                 end
             end
             @application_params[application] ||= Hash[self.where(:param_class=>application).collect(){|param| [param.name, param]}]
	     @application_params[application].values
	  end

          def self.application_param_hash(application)
	      self.application_params(application)
              @application_params[application]
	  end

	  def self.application_param_val(application, name)
	     self.application_params(application)
	     result = @application_params[application][name].conv_value if  @application_params[application][name].present?
	     result
	  end


	  # set an application param
	  def self.set_application_param(application, name, description_guid, value)
	     # refresh application param cache
	     self.application_params(application)

             raise Exception.new("Missing param description for #{name}") if description_guid.blank?

             param_description = Roxiware::Param::ParamDescription.find_description(description_guid)
	     raise Exception.new("Couldn't find param description #{description_guid} for #{name}") if param_description.blank?

	      if(value.class == Roxiware::Param::Param)
	         # if the value is a param just add it
	         @application_params[application][name].destroy
                 @application_params[application][name] = value
		 return value
              end

	     @application_params[application][name] ||= Param.new()
	     @application_params[application][name].update_attributes({:param_class=>application, 
	                                                               :name=>name,
			                                               :param_object_type=>nil, 
			                                               :description_guid=>description_guid, 
			                                               :param_object_id=>nil}, :as=>"")
	   
	      # set the value
	      case param_description.field_type
	        when "hash"
		  @application_params[application][name].params = value.values
		when "array"
		  @application_params[application][name].params = value.values
		when "text"
		  @application_params[application][name].textvalue = value
		else
		  @application_params[application][name].value = value
	      end

	      @application_params[application][name].save!
              @application_params[application][name]
	    end


	  def self.refresh_application_params
	     @application_params = {}
	  end

	  def description
	      Roxiware::Param::ParamDescription.find_description(self.description_guid)
	  end

	  def hash_params
	     @hash_params ||= Hash[params.collect{|param| [param.name, param]}]
             @hash_params
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
	     case description.field_type
	       when "array"
	         nil
	       when "hash"
                 nil
	       when "text"
                 textvalue
	       else
	         value
             end
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
	         value
	       when "text"
                 textvalue
	       when "float"
	         value.to_f
	       when "bool"
	         return (value == "true")
	       when "asset"
	         value
	       else
	         value
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
		when "text"
	          self.textvalue = param_value.children.select{|child| child.cdata?}.collect{|child| child.content}.join("")
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
             elsif self.param_description.field_type == "text"
	         xml_params.param(:class=>self.param_class, :name=>self.name, :description=>self.description_guid) { xml_params.cdata!(self.textvalue || "") }
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

	  def self.find_description(description_guid)
	      @param_descriptions ||= Hash[Roxiware::Param::ParamDescription.all.collect{|param_description| [param_description.guid, param_description]}]
	      @param_descriptions[description_guid]
	  end


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
