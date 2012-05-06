require 'devise'
require 'roxiware/engine'
autoload :AppConfig, 'roxiware/appconfig'

module Roxiware

  mattr_accessor :include_portfolio
  @@include_portfolio = false

  mattr_accessor :include_news
  @@include_news = false

  mattr_accessor :include_services
  @@include_services = false

  mattr_accessor :include_gallery
  @@include_gallery = false

  mattr_accessor :include_appearances
  @@include_appearances = false

  mattr_accessor :include_employees
  @@include_employees = false

  mattr_accessor :secret_page
  @@secret_page = nil?

  def self.setup
    yield self
  end

end

