# coding: utf-8
require 'spec_helper'

RSpec.describe Apress::Images::Extensions::BackgroundProcessing do
  describe '.process_in_background' do
    it do
      expect(DelayedImage.attachment_definitions[:img][:delayed]).to have_key(:processing_image_url)
      expect(DelayedImage.attachment_definitions[:img][:delayed][:processing_image_url]).to eq(
        described_class::DEFAULT_PROCESSING_IMAGE_PATH
      )
      expect(DelayedImage.attachment_definitions[:img][:delayed]).to have_key(:queue_name)
    end
  end

  describe '#enqueue_delayed_processing' do
    let(:image) { build :delayed_image }

    before { allow(Apress::Images::ProcessJob).to receive(:enqueue) }

    context 'when update processing field' do
      before { image.save! }

      it { expect(image).to be_processing }
    end

    context 'when enqueing' do
      before { image.save! }

      it do
        expect(Apress::Images::ProcessJob).to have_received(:enqueue).with(image.id, image.class.name)
      end
    end

    context 'when model saved twice in transaction' do
      before do
        allow(Apress::Images::ProcessJob).to receive(:enqueue).with(instance_of(Fixnum), image.class.name)
        ActiveRecord::Base.transaction do
          image.save!
          image.updated_at = image.updated_at + 1.day
          image.save!
        end
      end

      it do
        expect(image).to be_processing
        expect(Apress::Images::ProcessJob).to have_received(:enqueue).with(image.id, image.class.name).once
      end
    end
  end

  describe 'stub urls when image in processing' do
    let(:image) { create :delayed_image }
    let(:image_stub) { Rails.root.join('public/images/stub_thumb.gif') }

    context 'when image destroy' do
      before { image.destroy }

      it { expect(image).to be_destroyed }

      it 'reset procecesing flag' do
        expect(image).not_to be_processing
      end

      it 'keep stub image' do
        expect(File.exist?(image_stub)).to be
      end
    end
  end
end
