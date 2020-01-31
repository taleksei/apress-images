# coding: utf-8

module Apress
  module Images
    module Extensions
      # Internal: Содержит функционал для хранения изображений
      module Image
        extend ActiveSupport::Concern

        module ClassMethods
          # Public: Аттрибуты для хранения изображения
          #
          # Returns Array
          def img_attributes
            %W(
              #{attachment_attribute}_file_name
              #{attachment_attribute}_content_type
              #{attachment_attribute}_file_size
              #{attachment_attribute}_fingerprint
            ).freeze
          end
        end

        included do
          attr_reader :image_url
          attr_accessor :source_image_geometry

          has_attached_file attachment_attribute, attachment_options
          alias_attribute :img, attachment_attribute if attachment_attribute != :img

          validates_attachment_presence attachment_attribute, unless: :duplicate?
          validates_attachment_size attachment_attribute,
                                    less_than: max_size.megabytes,
                                    message: 'Размер файла не должен превышать %s Мб' % max_size
          validates_attachment_content_type attachment_attribute,
                                            message: 'Файл должен быть корректным изображением',
                                            content_type: allowed_mime_types

          validates_attachment_file_name attachment_attribute,
                                         matches: allowed_file_names,
                                         message: 'Файл должен быть корректным изображением'

          validate :corrupted_image_file_validation, unless: :duplicate?

          send "before_#{attachment_attribute}_post_process", :extract_source_image_geometry

          delegate :fingerprints,
                   :files,
                   :thumbs,
                   :most_existing_style,
                   :original_or_biggest_style,
                   :to_file,
                   to: attachment_attribute,
                   allow_nil: true

          after_rollback :clear_attachment, on: :create

          def corrupted_image_file_validation
            return if img.blank? || img.processing?

            adapter = Paperclip.io_adapters.for(img)
            stdout_stderr_output = `identify -verbose #{adapter.path} 2>&1`
            errors.add(:img_content_type, "Corrupted image: #{stdout_stderr_output}") if $CHILD_STATUS != 0
          end
        end

        def clear_attachment
          img.clear
          img.flush_deletes
        end

        # Public: список стилей
        #
        # Returns Array
        def styles
          img.styles.keys
        end

        # Public: Изменено ли изображение
        #
        # Returns Boolean
        def img_changed?
          img.dirty? || img_was_changed?
        end

        # Public: загрузка изображения по url
        #
        # Returns String
        def image_url=(url)
          self.img = Addressable::URI.parse(url).normalize.to_s
          @image_url = url
        end

        def image_url_provided?
          image_url.present?
        end

        private

        def img_was_changed?
          (previous_changes.keys & self.class.img_attributes).present?
        end

        # Internal: Сохрание размеров исходного изображения. Выполняется перед валидациями
        #           поэтому необходимо обработать ошибку некорректного формата изображения.
        #
        # Returns nothing.
        def extract_source_image_geometry
          return unless self.class.attachment_options.fetch(:need_extract_source_image_geometry)

          tempfile = img.queued_for_write[:original]
          self.source_image_geometry = Paperclip::Geometry.from_file(tempfile)
        rescue Paperclip::Errors::NotIdentifiedByImageMagickError
          nil
        end

        module ClassMethods
          # Public: параметры геометрии для определенного стиля.
          #
          # Returns Paperclip::Geometry.
          def style_geometry(style)
            geometry_string = attachment_definitions.
              fetch(attachment_attribute).
              fetch(:styles).
              fetch(style).
              fetch(:geometry)

            Paperclip::Geometry.parse(geometry_string)
          end
        end
      end
    end
  end
end
