# coding: utf-8

module Apress
  module Images
    class Engine < ::Rails::Engine
      config.autoload_paths += Dir["#{config.root}/lib"]
      config.autoload_paths += [config.root.join('app', 'models', 'concerns')] if Rails::VERSION::MAJOR < 4
      config.i18n.load_path += Dir[config.root.join('locales', '*.{rb,yml}').to_s]

      initializer 'apress-images', before: :load_config_initializers do
        config.imageable_models = Set.new(['Apress::Images::Image'])
        config.imageable_subjects = Set.new
      end

      initializer :define_apress_images_factories, after: 'factory_girl.set_factory_paths' do
        if defined?(FactoryGirl)
          FactoryGirl.definition_file_paths.unshift root.join('spec', 'factories')
        end
      end

      initializer :define_apress_images_migration_paths do |app|
        unless app.root.to_s.match root.to_s
          app.config.paths['db/migrate'].concat(config.paths['db/migrate'].expanded)
        end
      end
    end
  end
end
