# coding: utf-8

require 'spec_helper'

RSpec.describe Apress::Images::ProcessJob do
  describe '.execute' do
    let(:image) { create :subject_image, processing: true }

    before { allow_any_instance_of(Paperclip::Attachment).to receive(:process_delayed!) }

    it { expect_any_instance_of(Paperclip::Attachment).to receive(:process_delayed!) }

    after { described_class.execute(image.id, image.class.name) }
  end
end
