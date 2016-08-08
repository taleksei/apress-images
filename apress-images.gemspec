# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'apress/images/version'

Gem::Specification.new do |spec|
  spec.metadata['allowed_push_host'] = 'https://gems.railsc.ru'

  spec.name          = 'apress-images'
  spec.version       = Apress::Images::VERSION
  spec.authors       = ['Andrew N. Shalaev']
  spec.email         = %w(isqad88@yandex.ru)
  spec.summary       = %q{Apress images}
  spec.description   = %q{Universal image uploader}
  spec.homepage      = 'https://railsc.ru'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = %w(lib)

  spec.add_runtime_dependency 'rails', '>= 3.1.12', '< 5'
  spec.add_runtime_dependency 'pg'
  spec.add_runtime_dependency 'paperclip', '~> 4.2'
  spec.add_runtime_dependency 'russian', '>= 0.6'
  spec.add_runtime_dependency 'resque-integration', '>= 0.4.1'
  spec.add_runtime_dependency 'addressable', '>= 2.3.2'
  spec.add_runtime_dependency 'haml', '>= 4.0.7'
  spec.add_runtime_dependency 'rails-assets-FileAPI', '>= 2'
  spec.add_runtime_dependency 'class_logger', '~> 1.0.1'
  spec.add_runtime_dependency 'apress-api', '>= 1.8.0'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'json-schema'
  spec.add_development_dependency 'rspec', '>= 3.1'
  spec.add_development_dependency 'rspec-rails', '>= 2.14.0'
  spec.add_development_dependency 'appraisal', '>= 1.0.2'
  spec.add_development_dependency 'combustion', '>= 0.5.3'
  spec.add_development_dependency 'shoulda-matchers', '< 3'
  spec.add_development_dependency 'rspec-html-matchers', '>= 0.7'
  spec.add_development_dependency 'simplecov', '>= 0.9'
  spec.add_development_dependency 'test_after_commit', '>= 0.2.3', '< 0.5'
  spec.add_development_dependency 'mock_redis', '>= 0.15.3'
  spec.add_development_dependency 'webmock', '>= 1.24.2'
end
