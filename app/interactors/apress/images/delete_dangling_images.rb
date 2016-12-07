# coding: utf-8

require 'logger'

module Apress
  module Images
    # Public: удаление "висящих" картинок, то есть непривязанных к какой-либо сущности
    #
    # Examples:
    #   Apress::Images::DeleteDanglingImages.new(
    #     image_class: ProductImage,
    #     conditions: ['product_id IS NULL'],
    #     delete_limit: 1000,
    #     batch_size: 100,
    #     logger: Logger.new('deleting_process.log')
    #  ).call
    #
    #  Если необходимо останавливать процесс сразу после первой ошибки:
    #
    #  Apress::Images::DeleteDanglingImages.new(options).call!
    class DeleteDanglingImages
      BATCH_SIZE = 2_000
      DELETE_LIMIT = 5_000_000
      DEFAULT_CONDITIONS = ['subject_id IS NULL'].freeze

      attr_reader :image_class_name, :conditions, :batch_size, :delete_limit, :logger
      delegate :transaction, to: :images_klass

      def initialize(options)
        @image_class_name = options.fetch(:image_class).to_s
        @conditions = options.fetch(:conditions, DEFAULT_CONDITIONS)
        @batch_size = options.fetch(:batch_size, BATCH_SIZE)
        @delete_limit = options.fetch(:delete_limit, DELETE_LIMIT)
        @logger = options.fetch(:logger, Logger.new(STDOUT))
      end

      def call(options = {})
        logger.info <<-TEXT.strip_heredoc
          Start of deleting \"#{images_klass}\" images"
          Options: conditions: #{conditions.inspect} | batch size: #{batch_size} | delete limit: #{delete_limit}
        TEXT

        processed = 0

        while processed < delete_limit
          images = images_scope.to_a

          break if images.empty?

          begin
            transaction do
              clear_attachments(images)
              images_scope.unscoped.where(id: images.map(&:id)).delete_all
            end
          rescue => e
            logger.error "Error: \n\r#{e.inspect}\n\n #{e.backtrace.join("\n")}"
            raise e if options.fetch(:throw_exceptions, false)
          end

          processed += images.length

          logger.info "Processed #{processed}"
        end

        logger.info "Finish of deleting \"#{images_klass}\" images"
      end

      def call!
        call(throw_exceptions: true)
      end

      private

      def images_klass
        @image_klass ||= image_class_name.camelize.constantize
      end

      def images_scope
        images_klass.where(conditions).limit(batch_size)
      end

      def clear_attachments(images)
        images.each do |image|
          image.img.clear
          image.img.flush_deletes
        end
      end
    end
  end
end
