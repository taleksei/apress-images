# coding: utf-8

require 'spec_helper'

RSpec.describe Apress::Images::ImagesController, type: :controller do
  before do
    Rails.application.config.imageable_models << 'SubjectImage'
  end

  let(:image_in_process) { create :subject_image, processing: true }
  let(:image) { create :subject_image }

  describe '#previews' do
    context 'when valid request' do
      before { get :previews, ids: [image_in_process.id, image.id], model: 'SubjectImage' }

      it { expect(JSON.parse(response.body)).to be_include(image_in_process.id.to_s => 'processing') }
    end

    context 'when invalid request' do
      before { get :previews }
      it { expect(response).to have_http_status :bad_request }
    end
  end

  describe '#create' do
    let(:image) { fixture_file_upload(Rails.root.join('../fixtures/images/sample_image.jpg'), 'image/jpeg', :binary) }

    context 'when upload images' do
      before { post :upload, model: 'SubjectImage', images: [image, image] }

      it { expect(JSON.parse(response.body)['ids'].size).to eq 2 }
      it { expect(SubjectImage.count).to eq 2 }
    end

    context 'when upload images with croping params' do
      before do
        post :upload,
             model: 'SubjectImage',
             crop_x: '150',
             crop_y: '20',
             crop_h: '100',
             crop_w: '100',
             images: [image, image]
      end

      it 'crops all images to given size' do
        images = SubjectImage.all
        file_1 = Paperclip.io_adapters.for(images[0].img.styles[:big])
        expect(Paperclip::Geometry.from_file(file_1).to_s).to eq '100x100'
        file_2 = Paperclip.io_adapters.for(images[1].img.styles[:big])
        expect(Paperclip::Geometry.from_file(file_2).to_s).to eq '100x100'
      end
    end

    context 'when invalid file' do
      let(:wrong_image) { fixture_file_upload(Rails.root.join('../fixtures/images/txt_file.txt'), 'text/plain') }

      before { post :upload, model: 'SubjectImage', images: [wrong_image] }

      it { expect(JSON.parse(response.body)['status']).to eq 'error' }
    end
  end
end
