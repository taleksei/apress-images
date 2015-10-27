# coding: utf-8

module Apress
  module Images
    class Engine < ::Rails::Engine
      config.autoload_paths += Dir["#{config.root}/lib"]
      config.autoload_paths += [config.root.join('app', 'models', 'concerns')] if Rails::VERSION::MAJOR < 4
      config.i18n.load_path += Dir[config.root.join('config', 'locales', '*.{rb,yml}').to_s]

      initializer 'apress-images', before: :load_config_initializers do
        config.imageable_models = Set.new(['Apress::Images::Image'])
        config.imageable_subjects = Set.new

        Paperclip::Attachment.send(:include, Apress::Images::Extensions::Attachment)

        Paperclip::Attachment.default_options[:url_generator] = Apress::Images::UrlGenerator

        Paperclip.io_adapters.register Paperclip::UriAdapter do |target|
          target.is_a?(Addressable::URI)
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
