# coding: utf-8

require 'spec_helper'

RSpec.describe Apress::Images::ImagesController, type: :controller do
  before { Apress::Images::Image.post_process = false }

  let(:image_in_process) { create :image, processing: true }
  let(:image) { create :image }

  describe '#previews' do
    before do
      get :previews, ids: [image_in_process.id, image.id], model: 'Apress::Images::Image'
    end

    it { expect(JSON.parse(response.body)).to be_include(image_in_process.id.to_s => 'processing') }
  end

  describe '#create' do
    let(:image) do
      fixture_file_upload(Rails.root.join('../fixtures/images/sample_image.jpg'))
    end

    context 'when upload images' do
      before do
        post :upload, model: 'Apress::Images::Image', images: [image, image]
      end

      it { expect(JSON.parse(response.body)['ids'].size).to eq 2 }
      it { expect(Apress::Images::Image.count).to eq 2 }
    end

    context 'when invalid file' do
      let(:wrong_image) do
        fixture_file_upload(Rails.root.join('../fixtures/images/txt_file.txt'))
      end

      before do
        post :upload, model: 'Apress::Images::Image', images: [wrong_image]
      end

      it { expect(JSON.parse(response.body)['status']).to eq 'error' }
    end
  end
end
