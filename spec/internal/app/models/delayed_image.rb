class DelayedImage < ActiveRecord::Base
  include Apress::Images::Imageable

  acts_as_image(
    table_name: 'delayed_images',
    background_processing: true,
    queue_name: :base
  )
end
