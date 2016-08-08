source 'https://gems.railsc.ru'
source 'https://rubygems.org'

# Specify your gem's dependencies in apress-images.gemspec
gemspec

gem 'rails-assets-FileAPI', source: 'https://rails-assets.org/'

if RUBY_VERSION < '2'
  gem 'mime-types', '< 3.0'
  gem 'json', '< 2.0'
end

gem 'migration_comments', '= 0.3.2'

group :test do
  gem 'factory_girl_rails', require: false
end

group :development, :test do
  gem 'pry-debugger', require: false
end
