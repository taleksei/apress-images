# coding: utf-8

module Apress
  module Images
    # Public: Добавляет к сущностям возможность прикреплять картинки
    module Imageable
      extend ActiveSupport::Concern

      # Public: максимальный размер вложения, Мб
      MAX_SIZE = 2
      # Public: допустимые форматы
      ALLOWED_MIME_TYPES = %r{\Aimage/[^/]+\Z}.freeze
      # Public: путь к маленькому водяному знаку по-умолчанию
      WATERMARK_SMALL = File.join(Rails.public_path, 'images', 'pcwm-small.png').freeze
      # Public: путь к большому водяному знаку по-умолчанию
      WATERMARK_BIG = File.join(Rails.public_path, 'images', 'pcwm-big.png').freeze

      module ClassMethods
        # Public: Добавляет поведение картинки в модель active_record
        #
        # Returns nothing
        def acts_as_image(options = {})
          options.symbolize_keys!

          define_singleton_method :attachment_options do
            default_attachment_options.deep_merge(options.fetch(:attachment_options, {}))
          end

          define_singleton_method(:max_size) { options.fetch :max_size, MAX_SIZE }
          define_singleton_method(:allowed_mime_types) { options.fetch :allowed_mime_types, ALLOWED_MIME_TYPES }
          define_singleton_method(:watermark_small) { options.fetch :watermark_small, WATERMARK_SMALL }
          define_singleton_method(:watermark_big) { options.fetch :watermark_big, WATERMARK_BIG }

          include Apress::Images::Extensions::Imageable
          include(Apress::Images::Extensions::BackgroundProcessing) if options.fetch(:background_processing, true)
        end

        # Public: Опции по-умолчанию
        #
        # Returns Hash
        def default_attachment_options
          {
            use_file_command: true,
            default_style: :thumb,
            processors: [:watermark],
            convert_options: {
              all: '-strip -quality 90'
            },
            styles: {
              original: {
                geometry: '1280x1024>',
                format: 'jpg png gif',
                animated: false
              },
              thumb: {
                geometry: '90x90>',
                format: 'jpg png gif',
                animated: false,
                watermark_path: watermark_small
              }
            },
            url: '/system/images/:class/:id_partition_:style.:extension'
          }
        end
      end
    end
  end
end
