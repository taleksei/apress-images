# coding: utf-8

require 'spec_helper'

RSpec.describe Apress::Images::DeleteImages do
  describe '#call' do
    context 'when given conditions' do
      let(:service) do
        described_class.new(
          image_class: 'SubjectImage',
          conditions: ['img_updated_at < ? AND subject_id IS NULL', 1.minutes.ago]
        )
      end

      before do
        Timecop.travel(2.minutes.ago) do
          create :subject_image, subject_id: nil
        end
      end

      it { expect { service.call }.to change(SubjectImage, :count).from(1).to(0) }
    end

    context 'when limit reached' do
      let(:service) do
        described_class.new(
          image_class: 'SubjectImage',
          delete_limit: 2
        )
      end

      before do
        create_list :subject_image, 3, subject_id: nil
      end

      it do
        expect { service.call }.to change(SubjectImage, :count).from(3).to(1)
      end
    end
  end
end
