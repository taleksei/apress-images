# coding: utf-8

require 'spec_helper'

RSpec.describe Apress::Images::FormTagHelper, type: :helper do
  describe '#image_field_tag' do
    subject { helper.image_field_tag('img', subject_type: 'Foo', model: 'Bar') }

    it 'renders file field tag' do
      is_expected.to have_tag(
        :input,
        with: {
          class: %w(js-input-file-image dn),
          name: 'img',
          accept: '.jpg,.png'
        }
      )
    end

    it 'renders javascript' do
      is_expected.to have_tag(:script)
    end
  end
end
