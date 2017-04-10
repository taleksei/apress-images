require 'spec_helper'

RSpec.describe Paperclip::ManualCroper do
  let(:image) { build(:subject_image, img: nil) }

  before do
    class_double('DummySubject').as_stubbed_const
    allow(DummySubject).to receive(:model_name).and_return('DummySubject')
  end

  describe '.make' do
    context 'image is smaller than the original style geometry' do
      let(:image_file) do
        fixture_file_upload(Rails.root.join('../fixtures/images/sample_image.jpg'), 'image/jpeg', :binary)
      end
      let(:croper) { described_class.new(image_file, {}, image.img) }

      after do
        image.assign_attributes(crop_w: '200', crop_h: '100', crop_x: '10', crop_y: '20')
        image.img = image_file
        croper.make
      end

      it 'uses given dimensions for crop command' do
        expect(croper).to receive(:convert).with(/-crop 200x100\+10\+20 \+repage/, any_args)
      end
    end

    context 'image is bigger than the original style geometry' do
      let(:big_image_file) do
        fixture_file_upload(Rails.root.join('../fixtures/images/sample_big_image.png'), 'image/png', :binary)
      end
      let(:croper) { described_class.new(big_image_file, {}, image.img) }

      after do
        image.assign_attributes(crop_w: '1400', crop_h: '1000', crop_x: '40', crop_y: '46')
        image.img = big_image_file
        croper.make
      end

      it 'uses shrunk crop dimensions for crop command' do
        # размер изображения 1536x1126
        # размер оригинального стиля 1280x1024
        # коэф. уменьшения 1280.0 / 1536.0 = 0.8(3)
        #
        # width  - 1400 * 0.8(3) = 1167
        # height - 1000 * 0.8(3) = 833
        # x      - 40 * 0.8(3) = 33
        # y      - 46 * 0.8(3) = 38
        expect(croper).to receive(:convert).with(/-crop 1167x833\+33\+38 \+repage/, any_args)
      end
    end
  end
end
