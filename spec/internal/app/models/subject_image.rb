class SubjectImage < ActiveRecord::Base
  include Apress::Images::Imageable

  acts_as_image(background_processing: false)
end
