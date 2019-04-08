module Apress
  module Images
    module Extensions
      module Attachment
        module Deduplicable
          module FlushMethods
            def flush_writes
              return super unless duplicate?

              after_flush_writes
              @queued_for_write = {}
            end

            def flush_deletes
              return super unless duplicate?

              @queued_for_delete = []
            end
          end

          def reprocess!(*style_args)
            return if duplicate?

            super
          end

          def post_process
            return if duplicate?

            super
          end

          private

          def initialize_storage
            super
            extend(FlushMethods)
          end
        end
      end
    end
  end
end
