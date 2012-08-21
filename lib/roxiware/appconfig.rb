# Load application configuration
require 'ostruct'
require 'yaml'
config = YAML.load_file("#{Rails.root}/config/config.yml") || {}
app_config = config['common'] || {}
app_config.update(config[Rails.env] || {})
AppConfig = OpenStruct.new(app_config)


class ApplicationController < ActionController::Base
  def set_meta_info
    logger.debug("Set Meta Info")
  end

  before_filter :set_meta_info
end