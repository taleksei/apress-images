# coding: utf-8

module Apress
  module Images
    # Public: удаляет непривязанную к какому-либо объекту картинку
    class DeleteImageJob
      extend Resque::Plugins::ExponentialBackoff

      @queue = :images_deleting

      @backoff_strategy = [0, 30, 60, 120, 300]
      @retry_delay_multiplicand_max = 2.0

      def self.perform(image_id, class_name)
        image_class = class_name.to_s.constantize
        image = image_class.where(id: image_id).first

        return if image.nil? || image.subject_id.present?

        DeleteImages.new(
          image_class: image_class,
          conditions: ['id = ?', image_id],
          delete_limit: 1
        ).call
      end
    end
  end
end
