class HomeController < ApplicationController

  def index
      if Roxiware.enable_blog
         @post = @recent_posts.shift
      end

      if Roxiware.enable_gallery
        @gallery_item = Roxiware::GalleryItem.where(:gallery_id=>1).first
      end
  end

end
