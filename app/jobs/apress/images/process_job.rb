# coding: utf-8

require 'resque-integration'

module Apress
  module Images
    class ProcessJob
      include Resque::Integration

      queue :images

      unique { |image_id, _| [image_id] }

      def self.execute(image_id, class_name)
        model = class_name.camelize.constantize
        image = model.find_by_id(image_id)
        image.regenerate_styles! if image.present? && image.processing?
      end
    end
  end
end
