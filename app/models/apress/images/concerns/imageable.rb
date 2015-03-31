# coding: utf-8

require 'addressable/uri'

module Apress
  module Images
    module Concerns
      # Public: Добавляет к сущностям возможность прикреплять картинки
      #
      # Examples:
      #   class Image < ActiveRecord::Base
      #     # Define custom resizing
      #     def self.attachment_options
      #       {
      #         styles: {
      #           thumb: {geometry: '240x320>'}
      #         }
      #       }
      #     end
      #
      #     include Apress::Images::Concerns::Imageble
      #   end
      #
      module Imageable
        extend ActiveSupport::Concern
        # Public: максимальный размер вложения
        MAX_SIZE = 2
        # Public: допустимые форматы
        ALLOWED_MIME_TYPES = %r{\Aimage/[^/]+\Z}.freeze
        # Public: путь к маленькому водяному знаку по-умолчанию
        WATERMARK_SMALL = File.join(Rails.public_path, 'images', 'pcwm-small.png').freeze
        # Public: путь к большому водяному знаку по-умолчанию
        WATERMARK_BIG = File.join(Rails.public_path, 'images', 'pcwm-big.png').freeze
        # Public: Аттрибуты для хранения изобрежения
        IMG_ATTRIBUTES = %w(img_file_name img_content_type img_file_size img_fingerprint).freeze

        included do
          self.table_name = 'images'

          attr_writer :not_normalize_positions_on_callback
          attr_accessor :img_url
          alias_attribute :image_url, :img_url

          class << self
            attr_writer :not_normalize_positions_on_callback
          end

          before_validation :download_remote_image, if: proc { img_url.present? }

          after_save :normalize_positions,
                     if: proc { position_changed? || position.blank?  },
                     unless: :not_normalize_positions_on_callback

          after_destroy :normalize_positions,
                        unless: :not_normalize_positions_on_callback

          has_attached_file :img, attachment_options

          validates_attachment_presence :img
          validates_attachment_size :img,
                                    less_than: max_size.megabytes,
                                    message: I18n.t('activerecord.errors.too_large_file_size', max_size: max_size)
          validates_attachment_content_type :img,
                                            message: I18n.t('activerecord.errors.wrong_file_type'),
                                            content_type: allowed_mime_types
        end

        # Public: Стили
        #
        # Returns Array
        def styles
          img.styles.keys
        end

        # Public: Все стили кроме оригинала
        #
        # Returns Array
        def thumbs
          styles.reject { |s| s == :original }
        end

        # Public: Пути в файловой системе для каждого стиля
        #
        # Returns Hash
        def files
          styles.each_with_object({}) do |style, result|
            result[style] = img.path(style)
            result
          end
        end

        # Public: Расчитывает хеш для каждого стиля
        #
        # Returns Hash
        def fingerprints
          files.each_with_object({}) do |(style, file), result|
            result[style] = Digest::MD5.file(file).to_s
            result
          end
        end

        # Public: Изменено ли изображение
        #
        # Returns Boolean
        def img_changed?
          img.dirty? || img_was_changed?
        end

        def not_normalize_positions_on_callback
          return self.class.not_normalize_positions_on_callback if @not_normalize_positions_on_callback.nil?
          @not_normalize_positions_on_callback
        end

        protected

        def normalize_positions
          self.class.normalize_positions(subject_id, subject_type)
        end

        def download_remote_image
          self.img = fetch_remote_file
        end

        def fetch_remote_file
          io = open(Addressable::URI.parse(image_url))
          def io.original_filename
            base_uri.path.split('/').last
          end
          io.original_filename.present? ? io : nil
        rescue
          errors.add(:img_url, I18n.t('activerecord.errors.failed_to_download_remote_file'))
        end

        private

        def img_was_changed?
          (previous_changes.keys & IMG_ATTRIBUTES).present?
        end

        module ClassMethods
          def attachment_options
            options = {
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

            options.deep_merge!(super) if defined?(super)
            options
          end

          def max_size
            defined?(super) ? super : MAX_SIZE
          end

          def allowed_mime_types
            defined?(super) ? super : ALLOWED_MIME_TYPES
          end

          def watermark_small
            defined?(super) ? super : WATERMARK_SMALL
          end

          def watermark_big
            defined?(super) ? super : WATERMARK_BIG
          end

          # Public: Нормализация позиций в контексте subject_id - subject_type
          #
          # subject_id - Integer
          # subject_type - String
          #
          # Returns nothing
          def normalize_positions(subject_id, subject_type)
            return unless subject_id.present? && subject_type.present?

            table = quoted_table_name
            connection.execute <<-SQL
              UPDATE #{table} i SET position = t.real_position
              FROM
              (
                SELECT
                  id,
                  row_number() OVER (PARTITION BY subject_id, subject_type
                                     ORDER BY "position" NULLS LAST, created_at, id) AS real_position
                FROM
                  #{table}
                WHERE
                  subject_id = #{connection.quote(subject_id)} AND subject_type = #{connection.quote(subject_type)}
              ) t
              WHERE i.id = t.id;
            SQL
          end

          def not_normalize_positions_on_callback
            @not_normalize_positions_on_callback.nil? ? false : @not_normalize_positions_on_callback
          end
        end
      end
    end
  end
end
