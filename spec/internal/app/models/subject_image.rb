class SubjectImage < ActiveRecord::Base
  include Apress::Images::Imageable

  acts_as_image(
    attachment_options: {
      styles: {
        big: {
          geometry: '600x600>',
          animated: false
        },
        small: {
          geometry: '50x50>',
          animated: false
        }
      }
    },
    background_processing: false
  )
end
