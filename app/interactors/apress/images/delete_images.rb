# coding: utf-8

module Apress
  module Images
    # Public: удаление картинок
    #
    # Examples:
    #   Apress::Images::DeleteImages.new(
    #     image_class: ProductImage,
    #     conditions: ['product_id IS NULL'],
    #     delete_limit: 1000,
    #  ).call
    class DeleteImages
      DELETE_LIMIT = 1
      DEFAULT_CONDITIONS = ['subject_id IS NULL'].freeze

      attr_reader :image_klass, :conditions, :delete_limit
      delegate :transaction, to: :images_klass

      def initialize(options)
        @image_klass = options.fetch(:image_class)
        @image_klass = @image_klass.camelize.constantize if @image_klass.is_a?(String)

        @conditions = options.fetch(:conditions, DEFAULT_CONDITIONS)
        @delete_limit = options.fetch(:delete_limit, DELETE_LIMIT)
      end

      def call
        images = images_scope.to_a

        return if images.empty?

        clear_attachments(images)
        images_scope.unscoped.where(id: images.map!(&:id)).delete_all
      end

      private

      def images_scope
        image_klass.where(conditions).limit(delete_limit)
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
