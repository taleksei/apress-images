# coding: utf-8

require 'bundler/setup'
require 'apress/images'

require 'paperclip/matchers'

require 'combustion'
Combustion.initialize! :all do
  config.i18n.enforce_available_locales = false
  config.i18n.default_locale = :ru
end

require 'rspec/rails'
require 'factory_girl_rails'
require 'shoulda-matchers'
require 'rspec-html-matchers'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.include Paperclip::Shoulda::Matchers
  config.include ActionDispatch::TestProcess
  config.include RSpecHtmlMatchers
  config.use_transactional_fixtures = true
end
