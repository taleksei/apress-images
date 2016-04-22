# coding: utf-8

require 'bundler/setup'

require 'simplecov'
SimpleCov.start 'rails' do
  minimum_coverage 95
  add_filter 'lib/apress/images/engine.rb'
  add_filter 'lib/apress/images/version.rb'
end

require 'apress/images'

require 'combustion'
Combustion.initialize! :all do
  config.i18n.enforce_available_locales = false
  config.i18n.default_locale = :ru
end

require 'rspec/rails'
require 'factory_girl_rails'
require 'shoulda-matchers'
require 'paperclip/matchers'
require 'rspec-html-matchers'
require 'test_after_commit'
require 'webmock/rspec'

require 'mock_redis'
Resque.redis = MockRedis.new

Paperclip.options[:logger] = Rails.logger

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.include Paperclip::Shoulda::Matchers
  config.include ActionDispatch::TestProcess
  config.include RSpecHtmlMatchers
  config.use_transactional_fixtures = true
  config.filter_run_including focus: true
  config.run_all_when_everything_filtered = true
end
