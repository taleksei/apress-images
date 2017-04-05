# coding: utf-8

require 'bundler/setup'

require 'simplecov'
SimpleCov.start 'rails' do
  minimum_coverage 95
  add_filter 'lib/apress/images/engine.rb'
  add_filter 'lib/apress/images/version.rb'
  add_filter 'app/docs'
end

require 'apress/images'

require 'combustion'
Combustion.initialize! :all do
  config.i18n.enforce_available_locales = false
  config.i18n.default_locale = :ru
  config.asset_host = 'http://test'
end

require 'rspec/rails'
require 'factory_girl_rails'
require 'shoulda-matchers'
require 'paperclip/matchers'
require 'rspec-html-matchers'
require 'webmock/rspec'
require 'test_after_commit'
require 'apress/api/testing/json_matcher'
require 'timecop'

require 'mock_redis'
require 'pry-byebug'

Paperclip.options[:logger] = Rails.logger

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.include Paperclip::Shoulda::Matchers
  config.include ActionDispatch::TestProcess
  config.include RSpecHtmlMatchers
  config.use_transactional_fixtures = true
  config.filter_run_including focus: true
  config.run_all_when_everything_filtered = true

  Redis.current = MockRedis.new
  Resque.redis = Redis.current
end
