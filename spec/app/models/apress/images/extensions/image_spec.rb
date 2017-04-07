# coding: utf-8

require 'spec_helper'

RSpec.describe Apress::Images::Extensions::Image do
  let(:image) { build :subject_image }

  describe '#image_url=' do
    let(:dummy_filepath) { Rails.root.join('../fixtures/images/sample_image.jpg') }

    before do
      stub_request(:any, url).
        to_return(body: File.new(dummy_filepath), status: 200, headers: {'Content-Type' => 'image/jpeg'})
    end

    context 'when russian letters in url' do
      let(:url) { 'http://русский-язык.рф/file.jpg' }

      it do
        expect { image.image_url = url }.not_to raise_error
        image.image_url = url
        expect(image).to be_valid
      end
    end

    context 'when russian letters in filename' do
      let(:url) { 'http://example.com/картинка.jpg' }

      it 'transliterate filename'do
        expect { image.image_url = url }.not_to raise_error
        image.image_url = url
        expect(image).to be_valid
        expect(image.img_file_name).to eq 'kartinka.jpg'
      end
    end

    context 'when filename is longer than 255' do
      let(:url) { "http://example.com/x#{'y' * 251}.jpg" }

      it 'trim filename from beginning'do
        expect { image.image_url = url }.not_to raise_error
        image.image_url = url
        expect(image).to be_valid
        expect(image.img_file_name).to eq "#{'y' * 251}.jpg"
      end
    end

    context 'when extension in uppercase' do
      context 'when JPG' do
        let(:url) { 'http://русский-язык.рф/file.JPG' }

        it do
          image.image_url = url
          expect(image).to be_valid
        end
      end

      context 'when PNG' do
        let(:url) { 'http://русский-язык.рф/file.PNG' }

        it do
          image.image_url = url
          expect(image).to be_valid
        end
      end
    end
  end

  describe '#extract_source_image_geometry' do
    context 'file is a valid image' do
      let(:big_image_file) do
        fixture_file_upload(Rails.root.join('../fixtures/images/sample_big_image.png'), 'image/png', :binary)
      end
      let(:image) { build :subject_image, img: big_image_file }

      it do
        expect(image.source_image_geometry.width).to eq(1536.0)
        expect(image.source_image_geometry.height).to eq(1126.0)
      end
    end

    context 'file is not an image' do
      let(:text_file) { fixture_file_upload(Rails.root.join('../fixtures/images/txt_file.txt'), 'text/plain') }
      let(:image) { build :subject_image, img: text_file }

      before { image.save }

      it do
        expect(image).to_not be_persisted
        expect(image.errors).to include(:img_content_type)
      end
    end
  end
end
