module Apress
  module Images
    module Extensions
      module IoAdapters
        # Патч, исправляющий расширение файла, если оно не совпадает с содержимым
        module FixExtensions
          def original_filename
            current = super

            # при первой загрузке содержимое для некоторох адаптеров может отсутствовать
            return current if !current || @extension_fixed

            @extension_fixed = true
            config = Rails.application.config.images

            mime_types = config.fetch(:fix_mime_types_extensions) & MIME::Types[content_type]

            return current if mime_types.none?

            current_ext = File.extname(current).try(:[], 1..-1).try(:downcase)

            unless current_ext.present?
              @original_filename = "#{current}.#{mime_types.first.extensions.first}"
              return @original_filename
            end

            matching_mime_type = mime_types.any? { |mt| mt.extensions.any? { |ext| ext == current_ext } }

            return current if matching_mime_type

            @original_filename = "#{current}.#{mime_types.first.extensions.first}"
          end
        end
      end
    end
  end
end
