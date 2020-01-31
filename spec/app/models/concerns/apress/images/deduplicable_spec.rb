require 'spec_helper'

describe Apress::Images::Deduplicable do
  let(:file) { Rack::Test::UploadedFile.new(Rails.root.join('../fixtures/images/sample_image.jpg'), 'image/jpeg') }
  let(:original_style_file) do
    Rack::Test::UploadedFile.new(Rails.root.join("../internal/public#{image1.img.url(:original, false)}"), 'image/jpeg')
  end
  let(:self_img_file_exists) do
    ->(image) do
      parent_id = image.fingerprint_parent_id
      image.fingerprint_parent_id = nil
      img_exists = image.img.exists?(:original)
      image.fingerprint_parent_id = parent_id
      img_exists
    end
  end

  context 'when simple options' do
    describe SimpleDuplicatedImage, type: :model do
      let!(:image1) { create :simple_duplicated_image, subject_id: 1, subject_type: 'OfferImage', node: 2 }
      let!(:image2) { create :simple_duplicated_image, subject_id: 2, subject_type: 'ProductImage' }

      context 'when create duplicate' do
        it do
          expect(image1.fingerprint).to be_present
          expect(image1.fingerprint).to eq Paperclip.io_adapters.for(file).fingerprint
          expect(image1.img.exists?(:original)).to be_truthy
          expect(image1.img_fingerprint).to be_present
          expect(image1.img_fingerprint).to eq Paperclip.io_adapters.for(original_style_file).fingerprint
          expect(image1.processing).to be_falsey
          expect(image1.node).to eq 2

          expect(image2.fingerprint).to eq image1.fingerprint
          expect(image2.img_fingerprint).to eq image1.img_fingerprint
          expect(image2.img_file_name).to eq image1.img_file_name
          expect(image2.img_content_type).to eq image1.img_content_type
          expect(image2.img_file_size).to eq image1.img_file_size
          expect(self_img_file_exists.call(image2)).to be_falsey
          expect(image2.fingerprint_parent_id).to eq image1.id
          expect(image2.processing).to be_falsey
          expect(image2.node).to eq 2

          expect(image2.img.url(:original, false)).to eq image1.img.url(:original, false)
        end
      end

      context 'when destroy duplicate' do
        before { image2.destroy }

        it { expect(image1.img.exists?(:original)).to be_truthy }
      end

      context 'when destroy fingerprint parent' do
        it do
          image1.destroy
          expect(image2.class.where(id: image2.id)).to_not be_exists
          expect(image1.reload).to be
          expect(image1.subject_id).to eq 2
          expect(image1.subject_type).to eq 'ProductImage'
          expect(image1.img.exists?(:original)).to be_truthy
        end

        context 'when duplicate destroy enqueued' do
          before { image2.update_attributes(subject_id: nil) }

          it do
            image1.destroy
            expect(image2.class.where(id: image2.id)).to_not be_exists
            expect(image1.reload).to be
            expect(image1.subject_id).to be_nil
            expect(image1.subject_type).to eq 'ProductImage'
            expect(image1.img.exists?(:original)).to be_truthy
            expect(Resque.delayed?(Apress::Images::DeleteImageJob, image1.id, image1.class.to_s)).to be_truthy
          end
        end
      end

      context 'when destroy without duplicates' do
        before do
          image2.destroy
          image1.destroy
        end

        it do
          expect(image1.class.where(id: [image1.id, image2.id])).to_not be_exists
          expect(image1.img.exists?(:original)).to be_falsey
        end
      end

      context 'when reprocess duplicate' do
        before { image2.img.reprocess! }

        it { expect(self_img_file_exists.call(image2)).to be_falsey }
      end

      after { FileUtils.rm_rf(Rails.root.join('../internal/public/system/images/simple_duplicated_images')) }
    end
  end

  context 'when default options' do
    before { allow(Resque).to receive(:enqueue_to) }

    describe DefaultDuplicatedImage, type: :model do
      let!(:image1) { create :default_duplicated_image }
      let!(:image2) { create :default_duplicated_image }

      context 'when create duplicate' do
        it do
          expect(Resque).to have_received(:enqueue_to).once.
            with(Apress::Images::ProcessJob.queue, Apress::Images::ProcessJob, image1.id, image1.class.name, {})
          expect(Resque.delayed?(Apress::Images::DeleteImageJob, image1.id, image1.class.to_s)).to be_truthy
          expect(Resque.delayed?(Apress::Images::DeleteImageJob, image2.id, image2.class.to_s)).to be_truthy

          expect(image1.fingerprint).to be_present
          expect(image1.fingerprint).to eq Paperclip.io_adapters.for(file).fingerprint
          expect(image1.img_fingerprint).to eq image1.fingerprint
          expect(image1.processing).to be_truthy

          expect(image2.fingerprint).to eq image1.fingerprint
          expect(image2.img_fingerprint).to eq image1.img_fingerprint
          expect(image2.img_file_name).to eq image1.img_file_name
          expect(image2.img_content_type).to eq image1.img_content_type
          expect(image2.img_file_size).to eq image1.img_file_size
          expect(image2.fingerprint_parent_id).to eq image1.id
          expect(image2.processing).to be_truthy

          expect(image2.img.url(:original, false)).to eq image1.img.url(:original, false)
        end
      end

      context 'when process fingerprint parent' do
        before do
          image1.img.process_delayed!
          image1.reload
          image2.reload
        end

        it do
          expect(image1.img.exists?(:original)).to be_truthy
          expect(image1.img_fingerprint).to be_present
          expect(image1.img_fingerprint).to eq Paperclip.io_adapters.for(original_style_file).fingerprint
          expect(image1.processing).to be_falsey

          expect(self_img_file_exists.call(image2)).to be_falsey
          expect(image2.fingerprint).to eq image1.fingerprint
          expect(image2.img_fingerprint).to eq image1.img_fingerprint
          expect(image2.img_file_name).to eq image1.img_file_name
          expect(image2.img_content_type).to eq image1.img_content_type
          expect(image2.img_file_size).to eq image1.img_file_size
          expect(image2.processing).to be_falsey

          expect(image2.img.url(:original, false)).to eq image1.img.url(:original, false)
        end
      end

      context 'when destroy duplicate' do
        it { expect(Resque::Job).to_not receive(:destroy) }

        after { image2.destroy }
      end

      context 'when destroy fingerprint parent on process' do
        it { expect(Resque::Job).to_not receive(:destroy) }

        after { image1.destroy }
      end

      context 'when destroy without duplicates' do
        it { expect(Resque::Job).to receive(:destroy).twice }

        after do
          image2.destroy
          image1.destroy
        end
      end

      context 'when parent image reprocess after duplicate builded' do
        let(:image3) do
          image = build :default_duplicated_image
          image1.img.process_delayed!

          image.save!
          image
        end

        it do
          expect(image3.reload.processing).to be_falsey

          expect(image3.fingerprint).to eq image1.fingerprint
          expect(image3.img_fingerprint).to eq image1.img_fingerprint
          expect(image3.img_file_name).to eq image1.img_file_name
          expect(image3.img_content_type).to eq image1.img_content_type
          expect(image3.img_file_size).to eq image1.img_file_size
          expect(image3.fingerprint_parent_id).to eq image1.id
        end
      end

      describe '#duplicate_from' do
        shared_examples_for 'duplicate_when_image1_original' do |image|
          let(:image3) do
            im = build :default_duplicated_image
            im.duplicate_from(send(image))
            im
          end

          it do
            expect(image3.fingerprint).to eq image1.fingerprint
            expect(image3.img_fingerprint).to eq image1.img_fingerprint
            expect(image3.img_file_name).to eq image1.img_file_name
            expect(image3.img_content_type).to eq image1.img_content_type
            expect(image3.img_file_size).to eq image1.img_file_size
            expect(image3.fingerprint_parent_id).to eq image1.id
            expect(image3.processing).to be_truthy

            expect(image3.img.url(:original, false)).to eq image1.img.url(:original, false)
          end
        end

        it_behaves_like 'duplicate_when_image1_original', 'image1'

        context 'when duplicate from duplicate' do
          it_behaves_like 'duplicate_when_image1_original', 'image2'
        end
      end

      after { FileUtils.rm_rf(Rails.root.join('../internal/public/system/images/default_duplicated_images')) }
    end
  end
end
