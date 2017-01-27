require 'spec_helper'

RSpec.describe Apress::Images::DeleteImageJob do
  let(:image) { create :subject_image, subject_id: nil }

  describe '.perform' do
    context 'when subject_id present' do
      let(:image) { create :subject_image, subject_id: 1 }

      it 'does not deletes image' do
        described_class.perform(image.id, image.class)

        expect(image.class.where(id: image.id).first).to be_present
      end
    end

    context 'when subject_id is null' do
      it 'deletes image' do
        described_class.perform(image.id, image.class)

        expect(image.class.where(id: image.id).first).to be_nil
      end
    end

    context 'when passed non existance image_id' do
      it 'does not call delete service' do
        expect_any_instance_of(Apress::Images::DeleteImages).not_to receive(:call)

        described_class.perform(image.id + 1, image.class)
      end
    end
  end
end
