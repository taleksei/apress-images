# coding: utf-8

module Apress
  module Images
    # Public: Базовый класс для хранения изображений
    class Image < ::ActiveRecord::Base
      include Apress::Images::Concerns::Imageable

      self.abstract_class = true

      acts_as_image
    end
  end
end
