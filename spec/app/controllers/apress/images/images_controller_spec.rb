# coding: utf-8

require 'spec_helper'

RSpec.describe Apress::Images::ImagesController, type: :controller do
  before do
    Rails.application.config.imageable_models << 'SubjectImage'
    SubjectImage.post_process = false
  end

  let(:image_in_process) { create :subject_image, processing: true }
  let(:image) { create :subject_image }

  describe '#previews' do
    before do
      get :previews, ids: [image_in_process.id, image.id], model: 'SubjectImage'
    end

    it { expect(JSON.parse(response.body)).to be_include(image_in_process.id.to_s => 'processing') }
  end

  describe '#create' do
    let(:image) do
      fixture_file_upload(Rails.root.join('../fixtures/images/sample_image.jpg'), 'image/jpeg', :binary)
    end

    context 'when upload images' do
      before do
        post :upload, model: 'SubjectImage', images: [image, image]
      end

      it { expect(JSON.parse(response.body)['ids'].size).to eq 2 }
      it { expect(SubjectImage.count).to eq 2 }
    end

    context 'when invalid file' do
      let(:wrong_image) do
        fixture_file_upload(Rails.root.join('../fixtures/images/txt_file.txt'), 'text/plain')
      end

      before do
        post :upload, model: 'SubjectImage', images: [wrong_image]
      end

      it { expect(JSON.parse(response.body)['status']).to eq 'error' }
    end
  end
end
