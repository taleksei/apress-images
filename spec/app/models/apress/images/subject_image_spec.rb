# coding: utf-8

require 'spec_helper'

RSpec.describe SubjectImage, type: :model do
  let(:image) { build :subject_image }

  before { allow(Apress::Images::ProcessJob).to receive(:enqueue) }

  it { should have_attached_file(:img) }
  it { should validate_attachment_presence(:img) }
  it { should validate_attachment_content_type(:img).allowing('image/png', 'image/gif') }
  it { should validate_attachment_content_type(:img).rejecting('text/plain', 'text/xml') }
  it { should validate_attachment_size(:img).less_than(described_class.max_size.megabytes) }

  describe '#styles' do
    it { expect(image.styles).to eq described_class.attachment_options[:styles].keys }
  end

  describe '#thumbs' do
    it { expect(image.thumbs).to eq described_class.attachment_options[:styles].keys.reject { |s| s == :original } }
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

  describe '#store_img_status_changing' do
    let(:image) { create :subject_image }

    it { expect(image.instance_variable_get(:@_img_changed)).to eq true }
  end
end
