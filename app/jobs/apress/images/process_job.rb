# coding: utf-8

module Apress
  module Images
    class ProcessJob
      def self.queue
        :images
      end

      def self.non_online_queue
        :non_online_images
      end

      def self.perform(image_id, class_name)
        model = class_name.camelize.constantize
        image = model.find_by_id(image_id)

        image.img.process_delayed! if image.present? && image.processing?
      end

      ActiveSupport.run_load_hooks(:'apress/images/process_job', self)
    end
  end
end
