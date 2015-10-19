# coding: utf-8

require 'addressable/uri'

module Apress
  module Images
    module Extensions
      # Internal: Содержит функционал для хранения изображений
      module Imageable
        extend ActiveSupport::Concern
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

          scope :ordered, -> { order(arel_table[:position].asc) }

          before_validation :download_remote_image, if: proc { img_url.present? }

          after_save :normalize_positions,
                     if: proc { position_changed? || position.blank? },
                     unless: :not_normalize_positions_on_callback

          after_destroy :normalize_positions,
                        unless: :not_normalize_positions_on_callback

          has_attached_file :img, attachment_options

          validates_attachment_presence :img
          validates_attachment_size :img,
                                    less_than: max_size.megabytes,
                                    message: 'Размер файла не должен превышать %s Мб' % max_size
          validates_attachment_content_type :img,
                                            message: 'Файл должен быть корректным изображением',
                                            content_type: allowed_mime_types

          unless Apress::Images.old_paperclip?
            validates_attachment_file_name :img,
                                           matches: allowed_file_names,
                                           message: 'Файл должен быть корректным изображением'
          end
        end

        module ClassMethods
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
      end
    end
  end
end
