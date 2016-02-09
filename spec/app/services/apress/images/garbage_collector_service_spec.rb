# coding: utf-8

require 'spec_helper'

describe Apress::Images::GarbageCollectorService do
  let(:expired_time) { described_class.default_options[:expiration_time] - 1.day }

  describe '#call' do
    context 'when total of expired images within limit' do
      let!(:old_image) { create :subject_image, updated_at: expired_time }
      let!(:image) { create :subject_image }

      it { expect { described_class.new.call }.to change { Apress::Images::Image.all.count }.from(2).to(1) }
    end

    context 'when total of expired images out of limit' do
      let!(:old_images) { create_list :subject_image, 4, updated_at: expired_time }

      it do
        expect { described_class.new(images_limit: 2, batch_size: 1).call }
          .to change { Apress::Images::Image.all.count }.from(4).to(2).and raise_error
      end
    end
  end
end
