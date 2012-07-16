class HomeController < ApplicationController

  def index
      @categories = Hash[Roxiware::Terms::Term.categories().map {|category| [category.id, category]  }]
      if Roxiware.enable_blog
         @post = Roxiware::Blog::Post.order("post_date DESC").limit(1).first
      end
  end

end
