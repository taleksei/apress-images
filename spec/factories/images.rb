# coding: utf-8

FactoryGirl.define do
  factory :image, class: Apress::Images::Image do
    title 'Утро в сосновом бору'
    comment 'Картина русских художников Ивана Шишкина и Константина Савицкого.'
    img { Rack::Test::UploadedFile.new(Rails.root.join('../fixtures/images/sample_image.jpg'), 'image/jpeg') }
    position 1
  end

  factory :subject_image, class: SubjectImage do
    img { Rack::Test::UploadedFile.new(Rails.root.join('../fixtures/images/sample_image.jpg'), 'image/jpeg') }
    position 1
  end

  factory :delayed_image, class: DelayedImage do
    img { Rack::Test::UploadedFile.new(Rails.root.join('../fixtures/images/sample_image.jpg'), 'image/jpeg') }
    position 1
  end

  factory :delayed_image_with_crop, class: DelayedImageWithCrop do
    img { Rack::Test::UploadedFile.new(Rails.root.join('../fixtures/images/sample_image.jpg'), 'image/jpeg') }
    position 1
  end

  factory :custom_attribute_image, class: CustomAttributeImage

  factory :disordered_image, class: DisorderedImage do
    img { Rack::Test::UploadedFile.new(Rails.root.join('../fixtures/images/sample_image.jpg'), 'image/jpeg') }
  end
end
