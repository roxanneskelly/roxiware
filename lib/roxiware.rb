require 'devise'
require 'roxiware/engine'
autoload :AppConfig, 'roxiware/appconfig'

module Roxiware

  mattr_accessor :enable_portfolio
  @@enable_portfolio = false

  mattr_accessor :enable_news
  @@enable_news = false
end

