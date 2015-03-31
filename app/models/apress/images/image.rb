# coding: utf-8

module Apress
  module Images
    # Public: Базовый класс для хранения изображений
    class Image < ActiveRecord::Base
      self.abstract_class = true

      include Apress::Images::Concerns::Imageable
      include Apress::Images::Concerns::BackgroundProcessing
    end
  end
end
