# coding: utf-8

require 'spec_helper'

RSpec.describe SubjectImage, type: :model do
  let(:image) { build :subject_image }
  let(:dummy_filepath) { Rails.root.join('../fixtures/images/sample_image.jpg') }

  before { allow(Apress::Images::ProcessJob).to receive(:enqueue) }

  it { should have_attached_file(:img) }
  it { should validate_attachment_presence(:img) }
  it { should validate_attachment_content_type(:img).allowing('image/png', 'image/gif') }
  it { should validate_attachment_content_type(:img).rejecting('text/plain', 'text/xml') }
  it { should validate_attachment_size(:img).less_than(described_class.max_size.megabytes) }

  describe '#styles' do
    it { expect(image.styles).to eq described_class.attachment_options[:styles].keys }
  end

  describe 'delegated methods' do
    before { allow_any_instance_of(Paperclip::Attachment).to receive(:path).and_return(dummy_filepath) }

    it 'delegates attachment methods' do
      expect(image.thumbs).to eq(image.img.thumbs)
      expect(image.files).to eq(image.img.files)
      expect(image.fingerprints).to eq(image.img.fingerprints)
      expect(image.most_existing_style).to eq(image.img.most_existing_style)
      expect(image.original_or_biggest_style).to eq(image.img.original_or_biggest_style)
    end
  end

  describe '#normalize_positions' do
    context 'when save' do
      it { expect(described_class).to receive(:normalize_positions) }

      after { image.save! }
    end

    context 'when destroy' do
      let!(:image) { create :subject_image }

      it { expect(described_class).to receive(:normalize_positions) }

      after { image.destroy }
    end
  end
end
