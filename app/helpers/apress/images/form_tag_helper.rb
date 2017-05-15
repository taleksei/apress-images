# coding: utf-8

module Apress
  module Images
    module FormTagHelper
      # Public: формирует тег для загрузки изображений
      #
      # name - String, имя поля
      # options - Hash
      #  subject_type - String, сущность к которой крепим изображение (требуется указать)
      #  model - String, тип (модель) изображения (требуется указать)
      #  subject_id - Integer, id сущности
      #  class - String, класс для input
      #  accept - String, допустимые расширения файлов
      #  data - Hash, data-аттрибуты тега
      #  multiple - Boolean, определяет, разрешить ли мультизагрузку
      #  max_size - Integer, максимальный размер файла
      #  images_limit - Integer, макс. кол-во загружаемых файлов за раз
      #
      # Returns String
      def image_field_tag(name, options = {})
        field_options = {
          class: options.fetch(:class, 'js-input-file-image dn'),
          accept: options.fetch(:accept, '.jpg,.png'),
          data: options.fetch(:data, {}),
          multiple: options.fetch(:multiple, false)
        }

        js_options = {
          max_size: options.fetch(:max_size, Apress::Images::Image.max_size),
          size_type: options.fetch(:size_type, 'medium'),
          model: options.fetch(:model),
          images_limit: options.fetch(:images_limit, 1),
          subject_type: options.fetch(:subject_type),
          subject_id: options.fetch(:subject_id, ''),
          cropable: options.fetch(:cropable, false),
          crop_options: options.fetch(:crop_options, ''),
          original_style_width: options[:original_style_width],
          original_style_height: options[:original_style_height]
        }

        capture do
          concat file_field_tag name, field_options
          concat "\n"
          concat render(partial: 'apress/images/config', locals: {options: js_options})
        end
      end
    end
  end
end
