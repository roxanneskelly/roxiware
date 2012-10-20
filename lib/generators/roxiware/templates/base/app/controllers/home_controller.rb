class HomeController < ApplicationController
  include Roxiware::ApplicationControllerHelper
  def index
      @categories = Hash[Roxiware::Terms::Term.categories().map {|category| [category.id, category]  }]
      if Roxiware::Param::Param.application_param_val('blog', 'enable_blog')
         @post = Roxiware::Blog::Post.published().order("post_date DESC").limit(1).first
      end
  end
end
