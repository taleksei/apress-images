# coding: utf-8

module Apress
  module Images
    # Public: Добавляет к сущностям возможность прикреплять картинки
    module Imageable
      extend ActiveSupport::Concern
      # Public: таблица, где хранятся картинки, по-умолчанию
      TABLE_NAME = 'images'.freeze
      # Public: максимальный размер вложения, Мб
      MAX_SIZE = 15
      # Public: допустимые форматы
      ALLOWED_MIME_TYPES = /\Aimage\/(jpeg|png|gif|pjpeg)\Z/.freeze
      # Public: шаблоны допустимых названий файлов
      ALLOWED_FILE_NAMES = [/gif\Z/, /png\Z/, /jpe?g\Z/].freeze
      # Public: путь к маленькому водяному знаку по-умолчанию
      WATERMARK_SMALL = File.join(Rails.public_path, 'images', 'pcwm-small.png').freeze
      # Public: путь к большому водяному знаку по-умолчанию
      WATERMARK_BIG = File.join(Rails.public_path, 'images', 'pcwm-big.png').freeze
      # Public: опции по-умолчанию
      DEFAULT_OPTIONS = {
        default_style: :thumb,
        processors: [:watermark],
        convert_options: {
          original: '-strip -interlace Plane -quality 85',
          thumb: '-strip -quality 85'
        },
        styles: {
          original: {
            geometry: '1280x1024>',
            animated: false
          },
          thumb: {
            geometry: '90x90>',
            animated: false,
            watermark_path: WATERMARK_SMALL
          }
        },
        url: '/system/images/:class/:id_partition_:style.:extension'
      }.freeze

      COLUMN_POSITION_NAME = 'position'.freeze

      module ClassMethods
        # Public: Добавляет поведение картинки в модель active_record
        #
        # Returns nothing
        def acts_as_image(options = {})
          options.symbolize_keys!

          self.table_name = TABLE_NAME unless options[:table_name]

          define_singleton_method :attachment_options do
            default_attachment_options.deep_merge(options.fetch(:attachment_options, {}))
          end

          define_singleton_method(:max_size) { options.fetch :max_size, MAX_SIZE }
          define_singleton_method(:allowed_mime_types) { options.fetch :allowed_mime_types, ALLOWED_MIME_TYPES }
          define_singleton_method(:watermark_small) { options.fetch :watermark_small, WATERMARK_SMALL }
          define_singleton_method(:watermark_big) { options.fetch :watermark_big, WATERMARK_BIG }
          define_singleton_method(:allowed_file_names) { options.fetch :allowed_file_names, ALLOWED_FILE_NAMES }

          include Apress::Images::Extensions::Image

          if options.fetch(:position_normalizing, true) && column_names.include?(COLUMN_POSITION_NAME)
            include Apress::Images::PositionNormalizable
          end

          return unless options.fetch(:background_processing, true)

          include(Apress::Images::Extensions::BackgroundProcessing)

          process_in_background options.slice(:processing_image_url, :queue_name)
        end

        # Public: Опции по-умолчанию
        #
        # Returns Hash
        def default_attachment_options
          DEFAULT_OPTIONS
        end
      end
    end
  end
end
