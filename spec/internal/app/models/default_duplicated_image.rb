class DefaultDuplicatedImage < ActiveRecord::Base
  include Apress::Images::Imageable

  self.table_name = 'duplicated_images'

  acts_as_image(
    table_name: 'duplicated_images',
    deduplication: true,
    deduplication_copy_attributes: %w(processing)
  )
end
