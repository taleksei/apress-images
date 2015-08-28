# coding: utf-8
class Subject < ActiveRecord::Base
  include Apress::Images::ActsAsSubjectable

  acts_as_subject_of_images :has_one,
                            :cover,
                            class_name: 'SubjectImage', as: :subject
end
