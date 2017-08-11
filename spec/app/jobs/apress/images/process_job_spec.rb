require 'spec_helper'

RSpec.describe Apress::Images::ProcessJob do
  describe '.perform' do
    context 'success' do
      let(:image) { create :subject_image, processing: true }

      it do
        expect_any_instance_of(Paperclip::Attachment).to receive(:process_delayed!)
        described_class.perform(image.id, image.class.name)
      end
    end

    context 'opts are present but image was deleted' do
      it do
        expect do
          described_class.perform(
            nil,
            'SubjectImage',
            'assign_attributes' => {
              'crop_w' => '709',
              'crop_h' => '359',
              'crop_x' => '419',
              'crop_y' => '0'
            }
          )
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
