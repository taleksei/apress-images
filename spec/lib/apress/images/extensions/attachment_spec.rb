# coding: utf-8

require 'spec_helper'

RSpec.describe Paperclip::Attachment do
  let(:image) { build_stubbed :delayed_image }
  let(:dummy_filepath) { Rails.root.join('../fixtures/images/sample_image.jpg') }
  let(:dummy_fingerprint) { Digest::MD5.file(dummy_filepath).to_s }

  before do
    # не даем писать на диск
    allow_any_instance_of(Paperclip::Attachment).to receive_messages(flush_writes: nil, flush_deletes: nil)
  end

  describe '#processing?' do
    let(:image) { build :subject_image }

    it { expect(image.img).to respond_to :processing? }
  end

  describe '#delayed_options' do
    context 'when process in background setted' do
      let(:options) { DelayedImage.new.img.delayed_options }

      it do
        expect(options[:processing_image_url]).to eq('foo.jpg')
        expect(options[:queue_name]).to eq(:base)
      end
    end

    context 'when not setted' do
      it { expect(SubjectImage.new.img.delayed_options).to be_nil }
    end
  end

  describe '#save_with_prepare_enqueuing' do
    it { expect { image.img.send(:save) }.to change(image, :processing?).from(false).to true }
  end

  describe '#process_delayed!' do
    let(:image) { build_stubbed :delayed_image, processing: true }

    before { allow(image).to receive(:save) }

    context 'when processing' do
      it do
        expect(image.img).to receive(:job_is_processing=).with(false).once
        expect(image.img).to receive(:job_is_processing=).with(true).once
        expect(image.img).to receive(:post_processing=).with(true)
      end

      after { image.img.process_delayed! }
    end

    context 'when processed' do
      before { image.img.process_delayed! }

      it { expect(image.processing).to be_falsy }
    end

    context 'when original missing' do
      let(:image) { create :subject_image }

      before do
        allow_any_instance_of(Paperclip::Attachment).to receive(:update_processing_column)
        File.unlink(image.img.path(:original))
      end

      it 'restores original from must existing style' do
        expect(image.img).not_to be_exists(:original)
        image.img.process_delayed!
        expect(image.img).to be_exists(:original)
      end
    end
  end

  describe '#most_existing_style' do
    before { allow_any_instance_of(described_class).to receive(:path).and_return(dummy_filepath) }

    it { expect(image.img.most_existing_style).to eq(:thumb) }
  end

  describe '#thumbs' do
    it { expect(image.img.thumbs).to match_array([:thumb]) }
  end

  describe '#files' do
    let(:expected_paths) do
      {
        original: image.img.path(:original),
        thumb: image.img.path(:thumb)
      }
    end

    it { expect(image.img.files).to eq expected_paths }
  end

  describe '#fingerprints' do
    let(:expected_hash) do
      {
        original: dummy_fingerprint,
        thumb: dummy_fingerprint
      }
    end

    before { allow_any_instance_of(described_class).to receive(:path).and_return(dummy_filepath) }

    it { expect(image.img.fingerprints).to eq(expected_hash) }
  end

  describe '#processing_image_url' do
    let!(:options_before) { DelayedImage.attachment_definitions[:img][:delayed] }

    context 'when stub url callable' do
      before do
        DelayedImage.attachment_definitions[:img][:delayed] = {
          processing_image_url: ->(img) { "test_#{img.instance.id}.jpg" }
        }
      end

      it 'constructs url with image context' do
        expect(image.img.processing_image_url).to eq("test_#{image.id}.jpg")
      end

      after { DelayedImage.attachment_definitions[:img][:delayed] = options_before }
    end

    context 'when background processing disabled' do
      before { DelayedImage.attachment_definitions[:img][:delayed] = nil }

      it { expect(image.img.processing_image_url).to be_nil }

      after { DelayedImage.attachment_definitions[:img][:delayed] = options_before }
    end

    context 'when stub url is string' do
      before do
        DelayedImage.attachment_definitions[:img][:delayed] = {
          processing_image_url: '/images/dummy/stub.jpg'
        }
      end

      it { expect(image.img.processing_image_url).to eq('/images/dummy/stub.jpg') }

      after { DelayedImage.attachment_definitions[:img][:delayed] = options_before }
    end
  end
end
