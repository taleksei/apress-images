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

    it { expect_any_instance_of(Paperclip::Attachment).to receive(:process_delayed!) }

    after { described_class.perform(image.id, image.class.name) }
  end
end
