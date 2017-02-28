# coding: utf-8

require 'spec_helper'

describe Apress::Images::CropImagePresenter do
  let(:view_context) { double('ActionView::Base') }
  let(:presenter) { described_class.new(view_context) }

  describe '#show' do
    before do
      allow(view_context).to receive(:capture).and_yield
      allow(view_context).to receive(:render).
        with('apress/images/presenters/crop_image_show', hash_including(presenter: instance_of(described_class))).
        and_return('crop_image_show')
    end

    it { expect(presenter.show).to eq('crop_image_show') }
  end
end
