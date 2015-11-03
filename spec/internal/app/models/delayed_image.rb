class DelayedImage < ActiveRecord::Base
  include Apress::Images::Imageable

  acts_as_image(
    background_processing: true,
    processing_image_url: 'foo.jpg',
    queue_name: :base
  )
end
