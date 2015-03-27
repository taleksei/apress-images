# coding: utf-8

require 'spec_helper'

describe Apress::Images::UploadService do
  let(:image) do
    fixture_file_upload(Rails.root.join('../fixtures/images/sample_image.jpg'))
  end

  describe '#upload' do
    subject { described_class.new('Apress::Images::Image') }

    context 'when source is file' do
      it { expect { subject.upload(image) }.to change(Apress::Images::Image, :count).by(1) }
    end
  end
end
