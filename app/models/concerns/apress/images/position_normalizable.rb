module Apress
  module Images
    module PositionNormalizable
      extend ActiveSupport::Concern

      included do
        scope :ordered, -> { order(arel_table[:position].asc) }

        attr_writer :not_normalize_positions_on_callback

        class << self
          attr_writer :not_normalize_positions_on_callback
        end

        after_save :normalize_positions,
                   if: proc { position_changed? || position.blank? },
                   unless: :not_normalize_positions_on_callback

        after_destroy :normalize_positions,
                      unless: :not_normalize_positions_on_callback
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
          connection.execute <<-SQL.strip_heredoc
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
            WHERE i.id = t.id AND
                  COALESCE(i.position, -1) != t.real_position;
          SQL
        end

        def not_normalize_positions_on_callback
          !!@not_normalize_positions_on_callback
        end
      end

      def not_normalize_positions_on_callback
        return self.class.not_normalize_positions_on_callback if @not_normalize_positions_on_callback.nil?
        @not_normalize_positions_on_callback
      end

      protected

      def normalize_positions
        self.class.normalize_positions(subject_id, subject_type)
      end
    end
  end
end
