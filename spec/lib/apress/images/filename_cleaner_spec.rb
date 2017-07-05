# coding: utf-8
require 'spec_helper'

RSpec.describe Apress::Images::FilenameCleaner do
  describe '#call' do
    let(:filename_cleaner) { described_class.new }
    let(:result) { filename_cleaner.call(filename) }

    context 'when filename has nonword symbols' do
      let(:filename) { '!@#$%^&*()+' }

      it { expect(result).to eq('_' * filename.length) }
    end

    context 'when filename length is bigger than 255' do
      let(:filename) { 'x' * 256 }

      it { expect(result).to eq('x' * 255) }
    end

    context 'when filename has cyrillic chars' do
      let(:filename) { 'картинка.jpg' }

      it { expect(result).to eq('kartinka.jpg') }
    end

    context 'when filename contains invalid UTF-8 sequences' do
      let(:filename) { "pic\xA0.jpg" }

      it do
        expect { result }.not_to raise_error
        expect(result).to eq('pic.jpg')
      end
    end

    context 'when unescaped filename result to invalid UTF-8 sequence' do
      let(:filename) { '1274071928_%D4%E0%F1%E0%E423.jpg' }

      it do
        expect { result }.not_to raise_error
        expect(result).to eq('1274071928_23.jpg')
      end
    end

    context 'when filename is uri escaped' do
      let(:filename) { '%D0%BA%D0%B0%D1%80%D1%82%D0%B8%D0%BD%D0%BA%D0%B0.jpg' }

      it { expect(result).to eq('kartinka.jpg') }
    end
  end
end
