class Roxiware::SitemapController < ApplicationController
  def index
      if Roxiware.enable_blog
         @posts = Roxiware::Blog::Post.all
      end
      if Roxiware.enable_people
         if Roxiware.single_person
            @person = Roxiware::Person.where(:show_in_directory=>false).first
	 else
	    @people = Roxiware::Person.where(:show_in_directory=>true)
	 end
      end
      respond_to do |format|
        format.xml { render :layout=>false }
      end
  end
end