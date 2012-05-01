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
    @meta_keywords=::AppConfig.meta_keywords
    @meta_description=::AppConfig.meta_description
    @title=::AppConfig.title
    if params[:format] != "json"
      @robots="index,follow"
    else
      @robots="noindex,nofollow"
    end
  end

  before_filter :set_meta_info
end