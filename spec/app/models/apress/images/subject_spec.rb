# coding: utf-8
require 'spec_helper'

RSpec.describe Subject, type: :model do
  let(:subject) { create :subject }

  it { expect(subject).to have_one(:cover).class_name('SubjectImage') }
  it { expect(described_class.reflect_on_association(:cover).options[:as]).to eq(:subject) }
  it { expect(subject).to accept_nested_attributes_for(:cover).allow_destroy(true) }
  it { expect(subject.cover).to be_kind_of SubjectImage }

  context 'when subject is new record' do
    context 'when create without cover' do
      let(:subject) { build :subject }

      before { subject.save }

      it { expect(subject.persisted?).to be_truthy }
      it { expect(subject.cover.persisted?).to be_falsey }
    end

    context 'when create with cover' do
      let(:image) { create :subject_image }
      let(:subject) { described_class.new(attributes_for(:subject).merge(cover_attributes: {'id' => image.id})) }

      before { subject.save }

      it { expect(subject.persisted?).to be_truthy }
      it { expect(subject.cover.persisted?).to be_truthy }
      it { expect(subject.cover).to eq image }
    end
  end

  context 'when subject exists' do
    context 'when subject has not cover' do
      context 'when update without cover' do
        let(:subject) { create :subject }

        before { subject.save }

        it { expect(subject.persisted?).to be_truthy }
        it { expect(subject.cover.persisted?).to be_falsey }
      end

      context 'when update with cover' do
        let(:subject) { create :subject }
        let(:image) { create :subject_image, subject_id: subject.id, subject_type: subject.class.name }

        before do
          subject.assign_attributes(cover_attributes: {'id' => image.id})
          subject.save
        end

        it { expect(subject.persisted?).to be_truthy }
        it { expect(subject.cover.persisted?).to be_truthy }
        it { expect(subject.cover).to eq image }
      end
    end

    context 'when subject has cover' do
      context 'when update without cover' do
        let(:subject) { create :subject_with_cover }

        before do
          subject.assign_attributes(subject.attributes)
          subject.save
        end

        it { expect(subject.persisted?).to be_truthy }
        it { expect(subject.cover.persisted?).to be_truthy }
      end

      context 'when replacing the cover' do
        let!(:subject) { create :subject_with_cover }
        let!(:old_cover) { subject.cover }
        let!(:new_cover) { create :subject_image }

        before do
          subject.cover_attributes = {'id' => new_cover.id}
        end

        it do
          expect(subject.cover).to eq(new_cover)
          expect(old_cover.subject_id).to eq(nil)
        end
      end

      context 'when updating the cover' do
        let(:subject) { create :subject_with_cover }

        before do
          subject.cover_attributes = {'id' => subject.cover.id, 'comment' => 'Tap'}
        end

        it { expect(subject.cover.comment).to eq('Tap') }
      end

      context "when simultaneously replacing the cover and updating some of it's attributes" do
        let(:subject) { create :subject_with_cover }
        let(:new_cover) { create :subject_image }

        before do
          subject.cover_attributes = {'id' => new_cover.id, 'comment' => 'Tap'}
        end

        it do
          expect(subject.cover).to eq(new_cover)
          expect(subject.cover.comment).to eq('Tap')
        end
      end

      context "when simultaneously replacing the cover and updating some of it's attributes with invalid values" do
        let!(:subject) { create :subject_with_cover }
        let!(:old_cover) { subject.cover }
        let!(:new_cover) { create :subject_image }

        before do
          subject.cover_attributes = {'id' => new_cover.id, 'img_content_type' => 1337}
        end

        it do
          expect(subject).to be_invalid
          expect(subject.errors).to include(:'cover.img_content_type')
          expect(subject.cover).to eq(new_cover)
          expect(old_cover.subject_id).to eq(nil)
        end
      end

      context 'when updating the cover with id of another cover that belongs to some other subject' do
        let!(:subject) { create :subject_with_cover }
        let!(:subject_cover) { subject.cover }
        let!(:other_subject) { create :subject_with_cover }
        let!(:other_subject_cover) { other_subject.cover }

        before do
          subject.cover_attributes = {'id' => other_subject_cover.id, 'comment' => 'Tap'}
        end

        it 'does not do anything' do
          expect(subject.cover).to eq(subject_cover)
          expect(other_subject.cover).to eq(other_subject_cover)
          expect(subject.cover.comment).to eq(nil)
        end
      end

      context 'when destroying the cover through the _destroy flag' do
        let(:subject) { create :subject_with_cover }

        before do
          subject.cover_attributes = {'id' => subject.cover.id, '_destroy' => '1'}
        end

        it { expect(subject.cover).to be_marked_for_destruction }
      end

      context 'when updating the cover without specifying id' do
        let(:subject) { create :subject_with_cover }

        before do
          subject.cover_attributes = {'comment' => 'Tap'}
          subject.save
        end

        it { expect(subject.cover.comment).to eq(nil) }
      end

      context 'when updating the cover by specifying nonexistent id' do
        let(:subject) { create :subject_with_cover }
        let(:nonexistent_id) { SubjectImage.last.id + 1 }

        it do
          expect do
            subject.cover_attributes = {'id' => nonexistent_id, 'comment' => 'Tap'}
          end.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when updating the cover with symbol keyed hash' do
        let(:subject) { create :subject_with_cover }

        before do
          subject.cover_attributes = {id: subject.cover.id, comment: 'Tap'}
        end

        it { expect(subject.cover.comment).to eq('Tap') }
      end
    end
  end
end
