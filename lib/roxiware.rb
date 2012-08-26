require 'devise'
require 'roxiware/engine'
autoload :AppConfig, 'roxiware/appconfig'

module Roxiware

  mattr_accessor :enable_portfolio
  @@enable_portfolio = false

  mattr_accessor :enable_books
  @@enable_portfolio = false

  mattr_accessor :enable_news
  @@enable_news = false

  mattr_accessor :enable_blog
  @@enable_blog = false

  mattr_accessor :enable_services
  @@enable_services = false

  mattr_accessor :enable_gallery
  @@enable_gallery = false

  mattr_accessor :enable_events
  @@enable_events = false

  mattr_accessor :enable_people
  @@enable_people = false

  mattr_accessor :secret_page
  @@secret_page = nil?

  mattr_accessor :single_person	
  @@single_person = false

  mattr_accessor :galleries_per_row
  @@galleries_per_row = 6

  mattr_accessor :gallery_items_per_row
  @@gallery_items_per_row = 6

  mattr_accessor :gallery_rows_per_page
  @@gallery_rows_per_page = 4

  mattr_accessor :blog_posts_per_page
  @@blog_posts_per_page = 6

  mattr_accessor :max_blog_posts_per_page
  @@max_blog_posts_per_page = 20

  mattr_accessor :blog_posts_per_feed
  @@blog_posts_per_feed = 10

  mattr_accessor :max_blog_posts_per_feed
  @@max_blog_posts_per_feed = 20

  mattr_accessor :blog_exerpt_length
  @@blog_exerpt_length = 500

  mattr_accessor :blog_title
  @@blog_title = "Your Blog Title"

  mattr_accessor :blog_description
  @@blog_description = "Your Blog Description"

  mattr_accessor :blog_language
  @@blog_language = "en-us"
 
  mattr_accessor :blog_allow_comments
  @@blog_allow_comments = true
  
  mattr_accessor :blog_allow_anonymous_comments
  @@blog_allow_anonymous_comments = true

  mattr_accessor :blog_moderate_comments
  @@blog_moderate_comments = false

  mattr_accessor :upload_image_file_type
  @@upload_image_file_type = ".png"

  mattr_accessor :upload_image_sizes
  @@upload_image_sizes = {
                            :thumbnail=>[64, 64],
			    :xsmall=>[100, 100],
			    :small=>[150, 150],
			    :medium=>[250, 250],
			    :large=>[350, 350],
			    :xlarge=>[500, 500],
			    :huge=>[600, 600]
                         }

  mattr_accessor :layout
  @@layout = ""

  mattr_accessor :goodreads_key
  @@goodreads_key = "351iVqrxyMaH4RKryyA"

  mattr_accessor :goodreads_secret
  @@goodreads_secret = "30bD292eiwGB8tS08TdQdDnkeWpWHzgMtLS5labOk"

  def self.setup
    yield self
  end

end

