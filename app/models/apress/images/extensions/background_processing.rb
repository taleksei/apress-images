# coding: utf-8

module Apress
  module Images
    module Extensions
      # Public: отложенная обработка изображений
      module BackgroundProcessing
        extend ActiveSupport::Concern

        included do
          # Public: callback должен быть "навешан" раньше callback'ов paperclip-attachment'а
          before_destroy :reset_processing_flag, if: :processing?
        end

        module ClassMethods
          # Public: конфигурирует модель изображения для обработки в фоне
          #
          # options - Hash,
          #   :processing_image_url - String, путь к картинке-заглушке
          #   :queue_name - Symbol, очередь обработки, по-умолчанию :images
          #
          # Returns nothing
          def process_in_background(options = {})
            attachment_definitions[:img][:delayed] = options.reverse_merge!(
              processing_image_url: nil,
              queue_name: :images # TODO: добавить возможность выставить в кастомную очередь
            )

            after_commit :enqueue_delayed_processing
          end
        end

        # Public: пометить для последующей обработки
        # вызывается перед сохранением attachment'а
        #
        # Returns nothing
        def prepare_enqueuing
          self.processing = true
          nil
        end

        protected

        # Internal: выставить в очередь на обработку
        #
        # Returns nothing
        def enqueue_delayed_processing
          return if !img_changed? || reload.processing?

          update_column(:processing, true)

          Apress::Images::ProcessJob.enqueue(id, self.class.name)
        end

        private

        def reset_processing_flag
          self.processing = false
          nil
        end
      end
    end
  end
end
