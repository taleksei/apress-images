# coding: utf-8
if defined? Subject
  FactoryGirl.define do
    factory :subject, class: Subject, parent: :image do

      factory :subject_with_cover do
        after(:build) { |subject| subject.cover = create(:image) }
      end
    end
  end
end
