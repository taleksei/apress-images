# coding: utf-8
require 'class_logger'

module Apress
  module Images
    # Public: Занимается очисткой мусорных картинок из базы
    #
    # Examples:
    #   GarbageCollectorService.new(expiration_time: '01.01.2015'.to_datetime, images_limit: 1_000_000).call
    #   # удалит картинки, обновлённые последний раз ранее 1 янв 2015, но не более 1 миллиона картинок
    class GarbageCollectorService
      include ClassLogger

      LOGGER_FILE_NAME = 'garbage_collector_images'.freeze

      attr_reader :options

      delegate :call, to: :deleting_service

      class << self
        def default_options
          {
            expiration_time: 1.days.ago.at_beginning_of_day,
            images_limit: 5_000_000,
            batch_size: 2000
          }
        end

        def logger_default_file_name
          LOGGER_FILE_NAME
        end
      end

      def initialize(options = {})
        @options = options.reverse_merge(self.class.default_options)
      end

      private

      def deleting_service
        @deleting_service ||= DeleteDanglingImages.new(
          image_class: Image,
          logger: logger,
          conditions: ['subject_id IS NULL AND updated_at < ?', options[:expiration_time]],
          delete_limit: options[:images_limit],
          batch_size: options[:batch_size]
        )
      end

      ActiveSupport.run_load_hooks(:'apress/images/garbage_collector_service', self)
    end
  end
end
