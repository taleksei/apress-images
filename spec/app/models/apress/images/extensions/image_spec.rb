# coding: utf-8

require 'spec_helper'

RSpec.describe Apress::Images::Extensions::Image do
  describe '#image_url=' do
    let(:image) { build :subject_image }
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
end
