$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "roxiware/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "roxiware"
  s.version     = Roxiware::VERSION
  s.authors     = ["Roxanne Skelly"]
  s.email       = ["roxanne@roxiware.com"]
  s.homepage    = "http://www.roxiware.com/"
  s.summary     = "Roxiware app development tools."
  s.description = "Various development tools for roxiware website development."
  s.authors     = ['Roxanne Skelly']

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "rails"
  s.add_dependency "protected_attributes"
  s.add_dependency "rmagick"
  s.add_dependency "devise"
  s.add_dependency "devise-encryptable"
  s.add_dependency "omniauth"
  s.add_dependency "omniauth-facebook"
  s.add_dependency "omniauth-twitter"
  s.add_dependency "cancan"
  s.add_dependency "railties"
  s.add_dependency "jquery-rails"
  s.add_dependency "uuid"
  s.add_dependency "macaddr"
  s.add_dependency "systemu"
  s.add_dependency "sanitize"
  s.add_dependency "acts_as_tree_rails3"
  s.add_dependency "httparty"
  s.add_dependency "libxml-ruby"
  #s.add_dependency "recaptcha"
  s.add_dependency "msgpack"
  s.add_development_dependency "sqlite3"
end
