# coding: utf-8

require 'spec_helper'

RSpec.describe Apress::Images::DanglingCleanable, type: :model do
  describe '#enqueue_dangling_image' do
    context 'when creating image' do
      let!(:image) { create :subject_image, subject_id: 1 }

      it do
        expect(Resque.delayed?(Apress::Images::DeleteImageJob, image.id, image.class.to_s)).to be_falsy
      end
    end

    context 'when creating dangling image' do
      let!(:image) { create :subject_image, subject_id: nil }

      it do
        expect(Resque.delayed?(Apress::Images::DeleteImageJob, image.id, image.class.to_s)).to be_truthy
      end
    end

    context 'when updating' do
      let!(:image) { create :subject_image, subject_id: nil }

      it do
        image.update_attributes!(subject_id: 1)
        expect(Resque.delayed?(Apress::Images::DeleteImageJob, image.id, image.class.to_s)).to be_falsy

        image.update_attributes!(subject_id: nil)
        expect(Resque.delayed?(Apress::Images::DeleteImageJob, image.id, image.class.to_s)).to be_truthy
      end
    end

    context 'when destroy dangling image' do
      let!(:image) { create :subject_image, subject_id: nil }

      before do
        image.destroy
      end

      it do
        expect(Resque.delayed?(Apress::Images::DeleteImageJob, image.id, image.class.to_s)).to be_falsy
      end
    end

    context 'when destroy image' do
      let!(:image) { create :subject_image, subject_id: 1 }

      before do
        image.destroy
      end

      it do
        expect(Resque.delayed?(Apress::Images::DeleteImageJob, image.id, image.class.to_s)).to be_falsy
      end
    end
  end
end
