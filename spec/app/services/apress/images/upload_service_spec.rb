# coding: utf-8

require 'spec_helper'

describe Apress::Images::UploadService do
  let(:subject_type) { 'DummySubject' }
  let(:image) do
    fixture_file_upload(Rails.root.join('../fixtures/images/sample_image.jpg'), 'image/jpeg', :binary)
  end

  before do
    Rails.application.config.imageable_models << 'SubjectImage'
    stub_const(subject_type, Class.new)
    allow(DummySubject).to receive(:model_name).and_return(subject_type)
  end

  describe '#upload' do
    context 'when source is file' do
      context 'when create a new image' do
        subject { described_class.new('SubjectImage') }

        it { expect { subject.upload(image) }.to change(SubjectImage, :count).by(1) }
      end

      context 'when update an existing image' do
        let(:old_image) { create :subject_image }
        subject { described_class.new('SubjectImage', id: old_image.id) }

        before { old_image }

        it { expect { subject.upload(image) }.not_to change(SubjectImage, :count) }
      end
    end

    context 'when subject_type only present' do
      subject { described_class.new('SubjectImage', subject_type: subject_type) }

      before do
        allow_any_instance_of(described_class).to receive(:allowed_subjects).and_return [subject_type]
      end

      it { expect(subject.upload(image).subject_type).to eq subject_type }
    end

    context 'when subject_type is not allowed' do
      subject { described_class.new('SubjectImage', subject_type: subject_type) }

      it { expect { subject.upload(image) }.to raise_error(ArgumentError) }
    end
  end
end
