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

  spec.add_runtime_dependency 'rails', '>= 3.1.12', '< 4.1'
  spec.add_runtime_dependency 'pg'
  spec.add_runtime_dependency 'resque-integration', '>= 0.4.1'
  spec.add_runtime_dependency 'addressable', '>= 2.3.2'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '>= 3.1'
  spec.add_development_dependency 'rspec-rails', '>= 2.14.0'
  spec.add_development_dependency 'appraisal', '>= 1.0.2'
  spec.add_development_dependency 'combustion', '>= 0.5.3'
  spec.add_development_dependency 'factory_girl_rails'
  spec.add_development_dependency 'shoulda-matchers', '>= 2.8.0'
  spec.add_development_dependency 'pry-debugger'
end
