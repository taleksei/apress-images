# coding: utf-8
require 'spec_helper'

RSpec.describe Apress::Images::UrlGenerator do
  describe '#most_appropriate_url' do
    let!(:options_before) { DelayedImage.attachment_definitions[:img][:delayed] }

    context 'when stub url present' do
      let(:processing_image) { create :delayed_image, processing: true }

      before do
        DelayedImage.attachment_definitions[:img][:delayed] = {
          processing_image_url: 'stub_:style.jpg'
        }
      end

      it 'returns interpolated paths to stub image' do
        expect(processing_image.img.url(:original)).to eq('stub_original.jpg')
        expect(processing_image.img.url(:thumb)).to eq('stub_thumb.jpg')
      end

      after { DelayedImage.attachment_definitions[:img][:delayed] = options_before }
    end
  end
end
