class Roxiware::SitemapController < ApplicationController
  def index
      if Roxiware::Param::Param.application_param_val('blog', 'enable_blog')
         @posts = Roxiware::Blog::Post.all
      end
      if Roxiware::Param::Param.application_param_val('people', 'enable_people')
	 @people = Roxiware::Person.where(:show_in_directory=>true)
      end

      respond_to do |format|
        format.xml { render :layout=>false }
      end
  end
end