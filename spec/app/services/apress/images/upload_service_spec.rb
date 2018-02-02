# coding: utf-8

require 'spec_helper'

describe Apress::Images::UploadService do
  let(:subject_type) { "Subject" }

  let(:dummy_filepath) { Rails.root.join('../fixtures/images/sample_image.jpg') }

  let(:image) do
    fixture_file_upload(dummy_filepath, 'image/jpeg', :binary)
  end
  
  let(:image_url) do
    'http://example.com/file.jpg'.tap do |url|
      stub_request(:any, url).
        to_return(body: File.new(dummy_filepath), status: 200, headers: {'Content-Type' => 'image/jpeg'})
    end
  end

  before do
    Rails.application.config.imageable_models << 'SubjectImage'
  end

  describe '#upload' do
    shared_examples 'source given' do
      context 'when create a new image' do
        subject { described_class.new('SubjectImage') }

        it { expect { subject.upload(source) }.to change(SubjectImage, :count).by(1) }
      end

      context 'when update an existing image' do
        let(:old_image) { create :subject_image }
        subject { described_class.new('SubjectImage', id: old_image.id) }

        before { old_image }

        it { expect { subject.upload(source) }.not_to change(SubjectImage, :count) }
      end

      context 'when subject_type only present' do
        subject { described_class.new('SubjectImage', subject_type: subject_type) }

        before do
          allow_any_instance_of(described_class).to receive(:allowed_subjects).and_return [subject_type]
        end

        it { expect(subject.upload(source).subject_type).to eq subject_type }
      end

      context 'when subject_type and subject_id is present' do
        let(:subject_id) { create(:subject).id }
        subject { described_class.new('SubjectImage', subject_type: subject_type, subject_id: subject_id) }

        before do
          allow_any_instance_of(described_class).to receive(:allowed_subjects).and_return [subject_type]
        end

        it { expect(subject.upload(source).subject_type).to eq subject_type }
      end

      context 'when subject_type is not allowed' do
        subject { described_class.new('SubjectImage', subject_type: subject_type) }

        it { expect { subject.upload(source) }.to raise_error(ArgumentError) }
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
            uploaded_image = subject.upload(source)
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

      context 'when model has no position column' do
        before { Rails.application.config.imageable_models << 'DisorderedImage' }

        context 'when create a new image' do
          subject { described_class.new('DisorderedImage') }

          it { expect { subject.upload(source) }.to change(DisorderedImage, :count).by(1) }
        end

        context 'when update an existing image' do
          let!(:old_image) { create :disordered_image }
          subject { described_class.new('DisorderedImage', id: old_image.id) }

          it { expect { subject.upload(source) }.not_to change(DisorderedImage, :count) }
        end
      end
    end

    context 'when source is url' do
      let(:source) { image_url }

      it_behaves_like 'source given'
    end

    context 'when source is file' do
      let(:source) { image }

      it_behaves_like 'source given'
    end
  end
end
