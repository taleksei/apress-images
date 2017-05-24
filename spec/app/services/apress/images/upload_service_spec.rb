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

    context 'when crop parameters are given' do
      let(:crop_params) { {crop_w: '100', crop_h: '100', crop_x: '0', crop_y: '10'} }
      subject do
        described_class.new('SubjectImage', {subject_type: subject_type}.merge(crop_params))
      end

      before do
        allow_any_instance_of(described_class).to receive(:allowed_subjects).and_return [subject_type]
      end

      shared_examples 'croping image style according to given crop_ parameters' do
        it do
          uploaded_image = subject.upload(image)
          file = Paperclip.io_adapters.for(uploaded_image.img.styles[:big])

          expect(Paperclip::Geometry.from_file(file).to_s).to eq '100x100'
        end
      end

      context 'when creating a new image' do
        it_behaves_like 'croping image style according to given crop_ parameters'
      end

      context 'when updating an existing image' do
        let(:old_image) { create :subject_image }
        subject { described_class.new('SubjectImage', {id: old_image.id}.merge(crop_params)) }

        it_behaves_like 'croping image style according to given crop_ parameters'
      end
    end
  end
end
