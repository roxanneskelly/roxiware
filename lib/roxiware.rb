require 'devise'
require 'roxiware/engine'
autoload :AppConfig, 'roxiware/appconfig'

module Roxiware

  mattr_accessor :enable_portfolio
  @@enable_portfolio = false

  mattr_accessor :enable_news
  @@enable_news = false

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

  mattr_accessor :galleries_per_row
  @@gallery_rows_per_page = 6

  mattr_accessor :gallery_items_per_row
  @@gallery_items_per_row = 6

  mattr_accessor :gallery_rows_per_page
  @@gallery_items_per_row = 4

  def self.setup
    yield self
  end

end

