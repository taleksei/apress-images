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

      context 'when redirection http -> https' do
        let(:url) { 'http://someurl.ru' }

        before do
          stub_request(:any, url).
            to_return(body: 'Redirecting to https://someurl.ru',
                      status: 301,
                      headers: {'Content-Type' => 'text/html', 'Location' => 'https://someurl.ru'})

          stub_request(:any, 'https://someurl.ru').
            to_return(body: File.new(dummy_filepath), status: 200, headers: {'Content-Type' => 'image/jpeg'})
        end

        it do
          expect { image.image_url = url }.not_to raise_error
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

  describe '.style_geometry' do
    shared_examples_for '.style_geometry' do
      context 'given existent style' do
        it do
          expect(image.class.style_geometry(:original).width).to eq(1280.0)
          expect(image.class.style_geometry(:original).height).to eq(1024.0)
        end
      end

      context 'given nonexistent style' do
        it do
          expect { image.class.style_geometry(:non_existent).width }.to raise_error(KeyError)
        end
      end
    end

    context 'when model has custom attachment attribute' do
      let(:image) { build :custom_attribute_image }

      it_behaves_like '.style_geometry'
    end

    context 'when model has default attachment attribute' do
      it_behaves_like '.style_geometry'
    end
  end

  describe 'Callbacks' do
    describe '.clear_attachment' do
      let(:big_image_file) do
        fixture_file_upload(Rails.root.join('../fixtures/images/sample_big_image.png'), 'image/png', :binary)
      end

      let(:image) { build :subject_image, img: big_image_file }
      let(:path) { image.img.path }

      it do
        ActiveRecord::Base.transaction do
          image.save!

          expect(File).to exist(path)

          raise ActiveRecord::Rollback
        end

        expect(File).not_to exist(path)
      end
    end
  end
end
