source 'https://gems.railsc.ru'
source 'https://rubygems.org'

# Specify your gem's dependencies in apress-images.gemspec
gemspec

gem 'rails-assets-FileAPI', source: 'https://rails-assets.org/'

gem 'mime-types', '< 3.0' if RUBY_VERSION < '2'

group :test do
  gem 'factory_girl_rails', require: false
end

group :development, :test do
  gem 'pry-debugger', require: false
end
