# coding: utf-8

include ActionDispatch::TestProcess

FactoryGirl.define do
  factory :image, :class => Apress::Images::Image do
    title 'Утро в сосновом бору'
    comment 'Картина русских художников Ивана Шишкина и Константина Савицкого.'
    img { fixture_file_upload(Rails.root.join('../fixtures/images/sample_image.jpg')) }
    position 1
  end
end
