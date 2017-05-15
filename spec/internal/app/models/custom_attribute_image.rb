class CustomAttributeImage < ActiveRecord::Base
  include Apress::Images::Imageable

  acts_as_image(
    table_name: 'custom_attribute_images',
    attachment_attribute: :custom
  )
end
