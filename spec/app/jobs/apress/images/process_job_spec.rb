# coding: utf-8

require 'spec_helper'

RSpec.describe Apress::Images::ProcessJob do
  describe '.execute' do
    let(:image) { create :image, processing: true }

    it { expect_any_instance_of(Apress::Images::Image).to receive(:regenerate_styles!) }

    after { described_class.execute(image.id, image.class.name) }
  end
end
