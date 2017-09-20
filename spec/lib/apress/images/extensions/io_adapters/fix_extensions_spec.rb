require 'fileutils'
require 'stringio'
require 'spec_helper'

RSpec.describe Paperclip::AbstractAdapter do
  describe '#content_type' do
    context 'when jpg with php extension' do
      let(:copy_path) { 'spec/fixtures/images/copy.php' }

      before do
        FileUtils.copy_file('spec/fixtures/images/sample_image.jpg', copy_path)
      end

      after do
        FileUtils.remove_file(copy_path, true)
      end

      let(:adapter) { Paperclip.io_adapters.for(img) }

      context 'when image is UploadedFile' do
        context 'when content type match to original' do
          let(:img) { Rack::Test::UploadedFile.new copy_path, 'image/jpeg' }

          it { expect(adapter.original_filename).to eq 'copy.php.jpeg' }
        end

        context 'when content type did not match to original' do
          let(:img) { Rack::Test::UploadedFile.new copy_path, 'application/x-httpd-php' }

          context 'content type detector is default' do
            it { expect(adapter.original_filename).to eq 'copy.php.jpeg' }
          end

          context 'content type detector is file command' do
            let!(:old_content_type_detector) { Paperclip::UploadedFileAdapter.content_type_detector }

            before do
              Paperclip::UploadedFileAdapter.content_type_detector = Paperclip::FileCommandContentTypeDetector
            end

            after do
              Paperclip::UploadedFileAdapter.content_type_detector = old_content_type_detector
            end

            it { expect(adapter.original_filename).to eq 'copy.php.jpeg' }
          end
        end
      end

      context 'when image is File' do
        let(:img) { File.new(copy_path) }

        it { expect(adapter.original_filename).to eq 'copy.php.jpeg' }
      end

      context 'when image is StringIO' do
        let(:img) { StringIO.new(File.new(copy_path).read) }

        it { expect(adapter.original_filename).to eq 'data.jpeg' }
      end

      context 'when image is URI' do
        let(:img) { URI('http://example.com/pic.php') }

        context 'when content type specified' do
          before do
            WebMock.stub_request(:get, 'http://example.com/pic.php').
              to_return status: 200,
                        body: File.new(copy_path),
                        headers: {'Content-Type' => 'image/jpeg'}
          end

          it { expect(adapter.original_filename).to eq 'pic.php.jpeg' }
        end

        context 'when content type specified but wrong' do
          before do
            WebMock.stub_request(:get, 'http://example.com/pic.php').
              to_return status: 200,
                        body: File.new(copy_path),
                        headers: {'Content-Type' => 'application/x-httpd-php'}
          end

          it { expect(adapter.original_filename).to eq 'pic.php.jpeg' }
        end

        context 'when content type not specified' do
          before do
            WebMock.stub_request(:get, 'http://example.com/pic.php').
              to_return status: 200,
                        body: File.new(copy_path)
          end

          it { expect(adapter.original_filename).to eq 'pic.php.jpeg' }
        end
      end
    end

    context 'when jpg without extension' do
      let(:copy_path) { 'spec/fixtures/images/copy' }

      before do
        FileUtils.copy_file('spec/fixtures/images/sample_image.jpg', copy_path)
      end

      after do
        FileUtils.remove_file(copy_path, true)
      end

      let(:adapter) { Paperclip.io_adapters.for(img) }

      context 'when image is UploadedFile' do
        context 'when content type match to original' do
          let(:img) { Rack::Test::UploadedFile.new copy_path, 'image/jpeg' }

          it { expect(adapter.original_filename).to eq 'copy.jpeg' }
        end

        context 'when content type did not match to original' do
          let(:img) { Rack::Test::UploadedFile.new copy_path, 'application/x-httpd-php' }

          context 'content type detector is default' do
            it { expect(adapter.original_filename).to eq 'copy.jpeg' }
          end

          context 'content type detector is file command' do
            let!(:old_content_type_detector) { Paperclip::UploadedFileAdapter.content_type_detector }

            before do
              Paperclip::UploadedFileAdapter.content_type_detector = Paperclip::FileCommandContentTypeDetector
            end

            after do
              Paperclip::UploadedFileAdapter.content_type_detector = old_content_type_detector
            end

            it { expect(adapter.original_filename).to eq 'copy.jpeg' }
          end
        end
      end

      context 'when image is File' do
        let(:img) { File.new(copy_path) }

        it { expect(adapter.original_filename).to eq 'copy.jpeg' }
      end

      context 'when image is StringIO' do
        let(:img) { StringIO.new(File.new(copy_path).read) }

        it { expect(adapter.original_filename).to eq 'data.jpeg' }
      end

      context 'when image is URI' do
        let(:img) { URI('http://example.com/pic') }

        context 'when content type specified' do
          before do
            WebMock.stub_request(:get, 'http://example.com/pic').
              to_return status: 200,
                        body: File.new(copy_path),
                        headers: {'Content-Type' => 'image/jpeg'}
          end

          it { expect(adapter.original_filename).to eq 'pic.jpeg' }
        end

        context 'when content type specified but wrong' do
          before do
            WebMock.stub_request(:get, 'http://example.com/pic').
              to_return status: 200,
                        body: File.new(copy_path),
                        headers: {'Content-Type' => 'application/x-httpd-php'}
          end

          it { expect(adapter.original_filename).to eq 'pic.jpeg' }
        end

        context 'when content type not specified' do
          before do
            WebMock.stub_request(:get, 'http://example.com/pic').
              to_return status: 200,
                        body: File.new(copy_path)
          end

          it { expect(adapter.original_filename).to eq 'pic.jpeg' }
        end
      end
    end
  end
end
