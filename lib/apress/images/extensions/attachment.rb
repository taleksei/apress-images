# coding: utf-8

module Apress
  module Images
    module Extensions
      module Attachment
        extend ActiveSupport::Concern

        included do
          # Public: флаг, сигнализирующий о происходящей обработке
          attr_accessor :job_is_processing
          attr_writer :post_processing_with_delay

          alias_method_chain :post_processing, :delay
          alias_method_chain :post_processing=, :delay

          alias_method_chain :save, :prepare_enqueuing
        end

        # Public: находится ли attachment в обработке?
        #
        # Returns
        def processing?
          return unless instance.respond_to?(:processing?)
          instance.processing?
        end

        # Public: опции отложенной обработки
        # Возвращает из attachment_definitions[name][:delayed], выставленном при вызове
        # process_in_background на модели
        #
        # Returns Hash, nil если для модели не предусмотрена отложенная обработка
        def delayed_options
          options[:delayed]
        end

        # Public: запустить отложенную обработку
        #
        # Returns nothing
        def process_delayed!
          self.job_is_processing = true
          self.post_processing = true

          if exists?(:original)
            reprocess!
          else
            log("Original not exists for image #{instance.id}")

            begin
              file = to_file(most_existing_style)

              assign(file)

              reprocess!
            rescue
              log("Could not restore original for image #{instance.id}")
            ensure
              file.close if file
            end
          end

          self.job_is_processing = false

          update_processing_column
        end

        # Public: пометить модель для отложенной обработки
        #
        # Returns nothing
        def save_with_prepare_enqueuing
          was_dirty = @dirty

          save_without_prepare_enqueuing.tap do
            instance.prepare_enqueuing if delay_processing? && was_dirty
          end
        end

        # Public: запустить обработку вне фона
        #
        # Returns nothing
        def reprocess_without_delay!(*style_args)
          @post_processing_with_delay = true
          reprocess!(*style_args)
        end

        # Public: установлен ли флаг для отложенной обработки attаchment'а
        #
        # Returns Boolean
        def delay_processing?
          if @post_processing_with_delay.nil?
            !!delayed_options
          else
            !@post_processing_with_delay
          end
        end

        # Public: путь к картинке-заглушке
        #
        # Returns String
        def processing_image_url
          return unless delayed_options
          img_stub_path = delayed_options[:processing_image_url]
          img_stub_path = img_stub_path.call(self) if img_stub_path.respond_to?(:call)
          img_stub_path
        end

        def post_processing_with_delay
          !delay_processing?
        end

        # Public: стили кроме оригинала
        #
        # Returns Array
        def thumbs
          styles.keys.reject { |style| style == :original }
        end

        # Public: пути в файловой системе для каждого стиля
        #
        # Returns Hash
        def files
          styles.keys.each_with_object({}) do |style, result|
            result[style] = path(style)
            result
          end
        end

        # Public: список хешей для каждого стиля
        #
        # Returns Hash
        def fingerprints
          files.each_with_object({}) do |(style, file), result|
            result[style] = Digest::MD5.file(file).to_s
            result
          end
        end

        # Public: из всех стилей первый самый большой(по площади), файл которого существует
        #
        # Returns Symbol
        def most_existing_style
          thumbs
            .map do |style_name|
              geo = Paperclip::Geometry.parse(styles[style_name].geometry)
              area = geo.width * geo.height
              sort_value = -area # самые большие, при сортировке, встанут первыми
              [style_name, sort_value]
            end
            .sort_by(&:last)
            .find { |(style_name, _area)| exists?(style_name) }
            .try(:first)
        end

        # Public: выбирает стиль, если есть, то original, или самый большой (по площади)
        #
        # Returns Symbol
        def original_or_biggest_style
          if exists?(:original)
            :original
          else
            most_existing_style
          end
        rescue SocketError, Errno::EHOSTUNREACH => e
          log(e.message)
          :original
        end

        # Public: файл для стиля
        #
        # Returns Tempfile
        def to_file(style = default_style)
          file_path = path(style)
          tmpfile = Tempfile.new([File.basename(file_path), File.extname(file_path)])
          copy_to_local_file(style, tmpfile.path)
          tmpfile.rewind
          tmpfile
        end

        private

        # Internal: сбросить флаг фоновой обработки и записать в базу
        #
        # Returns nothing
        def update_processing_column
          return unless instance.processing?
          instance.processing = false
          instance.class.where(instance.class.primary_key => instance.id).update_all(processing: false)
        end
      end
    end
  end
end
