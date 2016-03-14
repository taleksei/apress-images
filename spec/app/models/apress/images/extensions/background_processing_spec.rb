# coding: utf-8
require 'spec_helper'

RSpec.describe Apress::Images::Extensions::BackgroundProcessing do
  describe '.process_in_background' do
    it do
      expect(DelayedImage.attachment_definitions[:img][:delayed]).to have_key(:processing_image_url)
      expect(DelayedImage.attachment_definitions[:img][:delayed]).to have_key(:queue_name)
    end
  end

  describe '#enqueue_delayed_processing' do
    let(:image) { build :delayed_image }

    before { allow(Apress::Images::ProcessJob).to receive(:enqueue) }

    context 'when update processing field' do
      before { image.save }

      it { expect(image).to be_processing }
    end

    context 'when enqueing' do
      it do
        expect(Apress::Images::ProcessJob).to receive(:enqueue).with(instance_of(Fixnum), image.class.name)
      end

      after { image.save }
    end
  end
end
