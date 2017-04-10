module Apress
  module Images
    module Cropable
      extend ActiveSupport::Concern

      CROP_ATTRS = [:crop_x, :crop_y, :crop_w, :crop_h].freeze

      included do
        class << self
          alias_method_chain :attachment_options, :crop
        end

        if instance_methods.include?(:options_for_delayed_enqueue)
          alias_method_chain :options_for_delayed_enqueue, :crop
        end

        attr_accessor(*CROP_ATTRS)
      end

      # Public: Нуждается ли изображение в кадрировании?
      #
      # Returns boolean.
      def need_croping?
        crop_x.present? && crop_y.present? && crop_w.present? && crop_h.present?
      end

      # Public: Если изображение нуждается в кадрировании, то к уже настроеным процессорам
      #         добавляем :manual_croper.
      #
      # style - Symbol название стиля для которого определять набор процессоров.
      #
      # Returns nothing.
      def compute_processors_with_crop(style)
        attachment_processors = img.processors
        style_processors = self.class.attachment_options_without_crop.
          fetch(:styles).
          fetch(style)[:processors]

        processors = style_processors || attachment_processors
        if need_croping?
          [:manual_croper] + (processors || [])
        else
          processors || [:thumbnail]
        end
      end

      # Public: В случае фоновой обработки изображения
      #         координаты кадрирования необходимо передать в джоб.
      #
      # Returns Hash.
      def options_for_delayed_enqueue_with_crop
        if need_croping?
          options_for_delayed_enqueue_without_crop.deep_merge(
            assign_attributes: {crop_x: crop_x, crop_y: crop_y, crop_w: crop_w, crop_h: crop_h}
          )
        else
          options_for_delayed_enqueue_without_crop
        end
      end

      module ClassMethods
        def attachment_options_with_crop
          attachment_options_without_crop
            .fetch(:styles)
            .each do |style, style_options|
              if cropable_styles.include?(style) && !style_options.is_a?(Hash)
                raise "#{name} #{style} style options needs to be a Hash"
              end
            end

          attachment_options_without_crop.deep_merge(
            styles: cropable_styles_options,
            need_extract_source_image_geometry: true
          )
        end

        private

        def cropable_styles_options
          cropable_styles.each_with_object({}) do |style, result|
            result[style] = {
              processors: ->(model) do
                model.compute_processors_with_crop(style)
              end
            }
          end
        end
      end
    end
  end
end
