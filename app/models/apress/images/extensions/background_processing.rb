# coding: utf-8

module Apress
  module Images
    module Extensions
      # Internal: Предоставляет возможность обработки изображения в фоне
      module BackgroundProcessing
        extend ActiveSupport::Concern

        included do
          attr_writer :post_process

          class << self
            attr_writer :post_process
          end

          before_img_post_process :prepare_image_to_process

          before_save :store_img_status_changing, if: :img_changed?
          after_commit :set_stubs, :enqueue_resizing, if: proc { post_process? && @_img_changed }
        end

        def regenerate_styles!
          img.reprocess!
          self.processing = false
          save(validate: false)
        end

        def post_process
          @post_process.nil? ? self.class.post_process : @post_process
        end

        def post_process?
          !!post_process
        end

        protected

        def store_img_status_changing
          @_img_changed = true
        end

        # Internal: Поставить в очередь на ресайзинг
        #
        # Returns nothing
        def enqueue_resizing
          Apress::Images::ProcessJob.enqueue(id, self.class.name)
          nil
        end

        # Internal: Прерывает ресайз картинки, если она изменилась
        # чтобы ресайзинг происходил в фоне
        #
        # Returns Boolean
        def prepare_image_to_process
          return if !post_process? || !img_changed?

          self.processing = true
          false # halts processing
        end

        # Intenal: Выставить заглушки
        def set_stubs
          return self unless img.file?

          thumbs.each do |name|
            tmp_file = ::Tempfile.new([name, '.gif'])
            ::FileUtils.cp stub_path(name), tmp_file.path
            img.queued_for_write[name] = tmp_file
          end

          img.flush_writes
        end

        def stub_path(style)
          return super if defined?(super)

          File.join(Rails.public_path, %W(images stub_#{style}.gif))
        end

        module ClassMethods
          # Public:class post process option, default true
          #
          # Returns boolean
          def post_process
            @post_process.nil? ? true : @post_process
          end

          def post_process?
            !!post_process
          end
        end
      end
    end
  end
end
