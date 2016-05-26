class DelayedImage < ActiveRecord::Base
  include Apress::Images::Imageable

  acts_as_image(
    background_processing: true,
    queue_name: :base
  )
end
