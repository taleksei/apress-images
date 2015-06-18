# coding: utf-8

require 'bundler/setup'
require 'apress/images'

require 'factory_girl_rails'
require 'paperclip/matchers'

require 'combustion'
Combustion.initialize! :all

require 'rspec/rails'
require 'shoulda-matchers'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.include Paperclip::Shoulda::Matchers
  config.include ActionDispatch::TestProcess
  config.use_transactional_fixtures = true
end
