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

      def self.default_options
        {
          expiration_time: 1.days.ago.at_beginning_of_day,
          images_limit: 5_000_000,
          batch_size: 2000
        }
      end

      def self.logger_default_file_name
        LOGGER_FILE_NAME
      end

      def initialize(options = {})
        @options = options.reverse_merge(self.class.default_options)
      end

      def call
        process_destroy Image.where(subject_id: nil).where('updated_at < ?', options[:expiration_time])
      end

      private

      def process_destroy(scope)
        logger.info "Удаление #{scope.klass}: старт."

        done = 0

        loop do
          images = scope.limit(options[:batch_size]).scoped

          break unless images.to_a.present?

          destroy_attached_files images

          scope.unscoped.where(id: images.map(&:id)).delete_all

          logger.info "Обработано ~ #{done += options[:batch_size]} картинок."

          if done >= options[:images_limit]
            e = "Достигнут предел в #{options[:images_limit]} удалённых картинок!"

            logger.error e
            raise e
          end
        end

        logger.info 'Процесс успешно завершен.'
      end

      def destroy_attached_files(images)
        images.each do |image|
          begin
            image.img.clear
            image.img.flush_deletes
          rescue => e
            logger.error "Ошибка: \n\r#{e.inspect}\n\n #{e.backtrace.join("\n")}"
          end
        end
      end

      ActiveSupport.run_load_hooks(:'apress/images/garbage_collector_service', self)
    end
  end
end
