class DisorderedImage < ActiveRecord::Base
  include Apress::Images::Imageable

  acts_as_image(table_name: 'disordered_images')
end
