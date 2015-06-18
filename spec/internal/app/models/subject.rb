# coding: utf-8
class Subject < Apress::Images::Image
  include Apress::Images::ActsAsSubjectable

  acts_as_image_subjectable(
    association_type: :has_one,
    association_name: :cover,
    association_class: Apress::Images::Image
  )
end
