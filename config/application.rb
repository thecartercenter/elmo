require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(*Rails.groups)

module ELMO
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # add concerns folders to autoload paths
    config.autoload_paths += [
      "#{config.root}/app/controllers/concerns",
      "#{config.root}/app/controllers/concerns/application_controller",
      "#{config.root}/app/models/concerns"
    ]

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # default to eastern -- this will be overwritten if there is a timezone setting in the DB
    config.time_zone = 'Eastern Time (US & Canada)'

    # be picky about available locales
    config.i18n.enforce_available_locales = true

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :password_confirmation]

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    config.generators do |g|
      g.test_framework :rspec
      g.integration_framework :rspec
    end

    ####################################
    # CUSTOM SETTINGS
    ####################################

    # read system version as git tag
    configatron.system_version = `git describe`.strip rescue "?"

    # regular expressions
    configatron.lat_lng_regexp = /^(-?\d+(\.\d+)?)\s*[,;:\s]\s*(-?\d+(\.\d+)?)/

    # a short tag that starts smses and email subjects for broadcasts
    configatron.broadcast_tag = "[TCC]"

    # locales with full translations (I18n.available_locales returns a whole bunch more defined by i18n-js)
    configatron.full_locales = [:en, :fr, :es]
  end
end
