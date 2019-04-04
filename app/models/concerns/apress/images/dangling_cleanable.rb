# coding: utf-8

module Apress
  module Images
    module DanglingCleanable
      extend ActiveSupport::Concern

      included do
        before_create -> { @enqueue_delete_dangling_image = true }, if: -> { subject_id.nil? }
        before_update -> { @enqueue_delete_dangling_image = true }, if: -> { subject_id_changed? && subject_id.nil? }
        before_update -> { @dequeue_delete_dangling_image = true }, if: -> { subject_id_changed? && subject_id }
        before_destroy -> { @dequeue_delete_dangling_image = true }, if: -> { subject_id.nil? }

        after_commit :enqueue_dangling_image, if: -> { @enqueue_delete_dangling_image }
        after_commit :dequeue_dangling_image, if: -> { @dequeue_delete_dangling_image }
      end

      private

      def enqueue_dangling_image
        Resque.enqueue_at(
          enqueue_at,
          Apress::Images::DeleteImageJob,
          id,
          self.class.to_s
        )
      ensure
        @enqueue_delete_dangling_image = false
      end

      def enqueue_at
        config = Rails.application.config.images

        config.fetch(:clear_dangling_after).seconds.since +
          rand(config.fetch(:clear_dangling_spread).to_i).seconds
      end

      def dequeue_dangling_image
        Resque.remove_delayed(
          Apress::Images::DeleteImageJob,
          id,
          self.class.to_s
        )
      ensure
        @dequeue_delete_dangling_image = false
      end
    end
  end
end
