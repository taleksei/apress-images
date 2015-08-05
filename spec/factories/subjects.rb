# coding: utf-8

FactoryGirl.define do
  factory :subject, class: Subject do
    factory :subject_with_cover do
      after(:build) { |subject| subject.cover = create(:subject_image) }
    end
  end
end
