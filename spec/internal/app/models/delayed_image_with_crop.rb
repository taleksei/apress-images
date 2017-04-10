class DelayedImageWithCrop < ActiveRecord::Base
  include Apress::Images::Imageable

  acts_as_image(
    attachment_options: {
      styles: {
        big: {
          geometry: '600x600>',
          animated: false
        }
      }
    },
    background_processing: true,
    queue_name: :base,
    cropable_styles: [:big],
    crop_options: {
      min_height: 100,
      min_width: 100
    }
  )
end
