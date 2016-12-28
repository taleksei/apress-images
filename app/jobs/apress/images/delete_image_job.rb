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
        conditions = ['subject_id IS NULL AND id = ?', image_id]

        DeleteImages.new(
          image_class: class_name,
          conditions: conditions,
          delete_limit: 1
        ).call
      end
    end
  end
end
