module Apress
  module Images
    module Extensions
      module IoAdapters
        # Патч, исправляющий content-type файла, если изначально его могли неправильно определить
        module FixContentType
          def content_type
            # при первой загрузке содержимое для некоторох адаптеров может отсутствовать
            return @content_type if !defined?(@content_type) || @content_type_fixed

            current = super

            @content_type_fixed = true
            config = Rails.application.config.images

            # content_type может быть неправильно определен или отсутствовать, если адаптер его определяет по расширению
            if !current || (config.fetch(:force_content_type_detect) & MIME::Types[current]).present?
              @content_type = Paperclip::FileCommandContentTypeDetector.new(path).detect
            end

            @content_type
          end
        end
      end
    end
  end
end
