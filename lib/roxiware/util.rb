module Roxiware
  module Util
    def store_location
      if params[:format] != "json"
         session[:return_to] = request.fullpath
      end
    end

    def redirect_back_or_default(default)
      session[:return_to] ? redirect_to(session[:return_to]) : redirect_to(default)
      session[:return_to] = nil
    end

    def return_to_location(default)
      session[:return_to] || default
    end

    def set_meta_info
      @meta_keywords=::AppConfig.meta_keywords
      @meta_description=::AppConfig.meta_description
      @title=::AppConfig.title
      if params[:format] != "json"
        @robots="index,follow"
      else
        @robots="noindex,nofollow"
      end
    end

    def swap_objects(object, other)
       begin
         ActiveRecord::Base.transaction do
           my_id = object.id
           other_id = other.id
           my_copy = object.dup
           other_copy = other.dup
	   other.delete
           object.delete
	   my_copy.id = other_id
	   my_copy.save
	   other_copy.id = my_id
	   other_copy.save()
           my_copy
         end
       rescue => e
	 object.errors.add("", e.msg)
         object
       end
    end
  end
end
