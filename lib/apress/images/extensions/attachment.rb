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

          reprocess!

          self.job_is_processing = false

          update_processing_column
          update_duplicates_processing
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

        def duplicate?
          instance.respond_to?(:duplicate?) && instance.duplicate?
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

        def update_duplicates_processing
          return unless instance.respond_to?(:fingerprint_original?) && instance.fingerprint_original?

          img_attributes = instance.class.img_attributes.each_with_object({}) do |attr, memo|
            memo[attr] = instance.attributes[attr] if instance.attributes.key?(attr)
          end
          img_attributes[:processing] = false

          instance.class.where(fingerprint_parent_id: instance.id).update_all(img_attributes)
        end
      end
    end
  end
end
