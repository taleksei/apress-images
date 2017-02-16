# coding: utf-8

require 'spec_helper'

RSpec.describe Apress::Images::Cropable, type: :model do
  let(:subject_type) { 'DummySubject' }
  let(:image) { build(:subject_image, img: nil) }
  let(:image_file) do
    fixture_file_upload(Rails.root.join('../fixtures/images/sample_image.jpg'), 'image/jpeg', :binary)
  end

  before do
    class_double('DummySubject').as_stubbed_const
    allow(DummySubject).to receive(:model_name).and_return(subject_type)
  end

  describe '#compute_processors_with_crop' do
    context 'when some processors already set for an attachment' do
      it do
        expect(image.img.processors).to eq([:watermark])
      end

      context 'when image needs to be croped' do
        before do
          image.assign_attributes(crop_x: '0', crop_y: '10', crop_h: '100', crop_w: '100')
        end

        it do
          expect(image.compute_processors_with_crop).to eq([:manual_croper, :watermark])
        end
      end

      context 'when image does not need to be croped' do
        it do
          expect(image.compute_processors_with_crop).to eq([:watermark])
        end
      end
    end
  end

  describe 'croping' do
    context 'when crop parameters are not given' do
      before do
        image.update_attributes!(img: image_file)
      end

      it 'does not crop cropable_style image' do
        file = Paperclip.io_adapters.for(image.img.styles[:big])

        expect(Paperclip::Geometry.from_file(file).to_s).to eq '400x271'
      end
    end

    context 'when crop parameters are given' do
      before do
        image.assign_attributes(crop_x: '0', crop_y: '10', crop_h: '100', crop_w: '100')
        image.update_attributes!(img: image_file)
      end

      it 'crops cropable_style image according to given params' do
        file = Paperclip.io_adapters.for(image.img.styles[:big])

        expect(Paperclip::Geometry.from_file(file).to_s).to eq '100x100'
      end
    end

    context 'when bad crop parameters are given' do
      before do
        image.assign_attributes(crop_x: 'sudo', crop_y: 'rm', crop_h: '-rf', crop_w: '/')
      end

      it 'fails on image processing' do
        expect { image.update_attributes!(img: image_file) }.to raise_error(ArgumentError)
      end
    end
  end
end
