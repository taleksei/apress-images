# coding: utf-8

module Apress
  module Images
    class ProcessJob
      include Resque::Integration

      queue :images

      unique

      def self.execute(image_id, class_name)
        model = class_name.camelize.constantize
        image = model.find_by_id(image_id)

        image.img.process_delayed! if image.present? && image.processing?
      end
    end
  end
end
