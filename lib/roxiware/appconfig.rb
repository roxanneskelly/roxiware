# Load application configuration
require 'ostruct'
require 'yaml'
config = YAML.load_file("#{Rails.root}/config/config.yml") || {}
app_config = config['common'] || {}
app_config.update(config[Rails.env] || {})

instance_file = Rails.root.join("config","instance_config.yml")
if File.file?(instance_file)
    instance_config = YAML.load_file(instance_file)
    app_config.update(instance_config)
end

AppConfig = OpenStruct.new(app_config)
