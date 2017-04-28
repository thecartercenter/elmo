source "http://rubygems.org"

gem "rails", "~> 4.2.5"

# Assets / Javascript
gem "sass-rails", "~> 4.0.5"
gem "uglifier", "~> 2.7.1"
gem "bootstrap-modal-rails", "~> 2.2.5"
gem "actionpack-page_caching", "~> 1.0.2"
gem "jquery-rails", "~> 4.0.4"
gem "jquery-fileupload-rails", "~> 0.4.5"
gem "rails-backbone", git: "https://github.com/codebrew/backbone-rails.git"
gem "dropzonejs-rails", "~> 0.7.3"
gem "phantomjs_polyfill-rails", "~> 1.0.0"

# Authentication
gem "activerecord-session_store", "~> 0.1.1"
gem "authlogic", "~> 3.4.5"
gem "scrypt", "~> 1.2.0"

# authorization
gem "cancancan", "~> 1.10.1"

# core
gem "rake", "~> 10.4.2"
gem "pg", "~> 0.20"
gem "mysql2", "~> 0.3.18"
gem "configatron", "~> 4.5.0"
gem "random_data", "~> 1.6.0"
gem "paperclip", "~> 4.3.2"
gem "term-ansicolor", "~> 1.3.0"
gem "therubyracer", "~> 0.12.2", platforms: :ruby
gem "draper", "~> 2.1.0"
gem "attribute_normalizer", "~> 1.2.0"
gem "responders", "~> 2.3.0"
gem "thor", "0.19.1" # Newer versions produce command line argument errors. Remove version constraint when fixed.
gem "friendly_id", "~> 5.1.0"

# pagination
gem "will_paginate", "~> 3.0.7"
gem "will_paginate-bootstrap", "~> 1.0.1"

# markdown support
gem "bluecloth", "~> 2.2.0"
gem "rdiscount", "~> 2.1.8"
gem "reverse_markdown", "~> 1.0.3"

# API
gem "versionist", "~> 1.4.1"
gem "active_model_serializers", "~> 0.9.3"
gem "api-pagination", "~> 4.1.1"

# Auto rank maintenance for sorted lists.
# The former master branch we were relying on is now a stable release
gem "acts_as_list", "~> 0.8.0"

# i18n
gem "i18n-js", "~> 3.0.0.rc13"
gem "rails-i18n", "~> 4.0.4"
gem "iso-639", "~> 0.2.5"
gem "i18n-country-translations", "~> 1.2.3"
gem "i18n_country_select", "~> 1.1.7"
# memcache
gem "dalli", "~> 2.7.4"

# foreign key maintenance
gem "immigrant", "~> 0.3.1"

# mean, median, etc.
gem "descriptive_statistics", "~> 2.5.1", require: "descriptive_statistics/safe"

# icons
gem "font-awesome-rails", "~> 4.7"

# Rich text editor
gem "ckeditor", "~> 4.2"

# Select box on steriods
gem "select2-rails", "~> 4.0"

# underscore templates
gem "ejs", "~> 1.1.1"

# background job support
gem "daemons", "~> 1.2.1"
gem "delayed_job_active_record", "~> 4.0.3"

# search
gem "thinking-sphinx", "~> 3.1.3"
gem "ts-delayed-delta", "~> 2.0.2"

# cron management
gem "whenever", "~> 0.9.4", require: false

# Bootstrap UI framework
gem "bootstrap-sass", "~> 3.3.4"

# spinner
gem "spinjs-rails", "1.3"

# tree data structure
gem "ancestry", "~> 2.1.0"

# Middleware for handling abusive requests
gem "rack-attack", git: "https://github.com/sassafrastech/rack-attack.git"

# reCAPTCHA support
gem "recaptcha", "~> 0.4.0", require: "recaptcha/rails"

# XLS support
gem "axlsx", "~> 2.1.0.pre"
gem "axlsx_rails", "~> 0.3.0"
gem "roo", "~> 2.1.1"

# Twilio SMS integration
gem "twilio-ruby", "~> 4.1.0"

# Phone number normalization
gem "phony", "~> 2.15.26"

# Temporarily included for converting MySQL to PostgreSQL
gem "mysql-pr", git: 'https://github.com/sassafrastech/mysql-pr.git'
gem "mysqltopostgres", git: "https://github.com/sassafrastech/mysql2postgres.git"

group :development do
  # generate diagrams with rake db:migrate
  gem "rails-erd", "~> 1.4.0"

  # query optimization
  gem "bullet", "~> 4.14.4"

  # development web server
  gem "thin", "~> 1.6.3"

  # speed up development mode
  gem "rails-dev-tweaks", "~> 1.2.0"
  gem "spring", "~> 1.3.3"

  # Better error pages
  gem "better_errors", "~> 2.1.1"
  gem "binding_of_caller", "~> 0.7.2"

  # misc
  gem "apiary", "~> 0.0.5"
  gem "fix-db-schema-conflicts", "~> 2.0.0"
  gem "letter_opener", "~> 1.4.1"
end

group :development, :test do
  # test framework
  gem "jasmine-rails", "~> 0.10.7"
  gem "rspec-rails", "~> 3.3.0"
  gem "rspec-collection_matchers", "~> 1.1.2"

  # mocking/stubbing/factories
  gem "mocha", "~> 1.1.0"
  gem "faker", "~> 1.6.3"
  gem "factory_girl_rails", "~> 4.5.0"

  # acceptance tests
  gem "capybara", "~> 2.4.4"
  gem "capybara-screenshot", "~> 1.0.11"
  gem "selenium-webdriver", "~> 2.45.0"
  gem "poltergeist", "~> 1.7.0"

  # cleans database for testing
  gem "database_cleaner", "~> 1.4.1"

   # sets time for testing
  gem "timecop", "~> 0.7.3"

  # for debugging/console, prints an object nicely
  gem "awesome_print", "~> 1.6.1"

  # test assertion
  gem "assert_difference", "~> 1.0.0"

  # auto-open capybara html file
  gem "launchy", "~> 2.4.3"

  # builds JMeter test plans
  gem "ruby-jmeter", "~> 2.13.4"

  # removes "get assets" from logs
  gem "quiet_assets", "~> 1.1.0"
end
