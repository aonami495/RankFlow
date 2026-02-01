# frozen_string_literal: true

require "rails_helper"

RSpec.describe Keyword, type: :model do
  describe "validations" do
    subject { build(:keyword) }

    it { is_expected.to validate_presence_of(:word) }
    it { is_expected.to validate_length_of(:word).is_at_most(100) }
    it { is_expected.to validate_uniqueness_of(:word).scoped_to(:site_id).with_message("has already been added to this site") }
  end

  describe "associations" do
    it { is_expected.to belong_to(:site) }
    it { is_expected.to belong_to(:article).optional }
    it { is_expected.to have_many(:rank_histories).dependent(:destroy) }
  end

  describe "#current_rank" do
    let(:keyword) { create(:keyword) }

    context "when there are rank histories" do
      before do
        create(:rank_history, keyword: keyword, rank: 10, checked_at: 2.days.ago)
        create(:rank_history, keyword: keyword, rank: 5, checked_at: Date.current)
      end

      it "returns the most recent rank" do
        expect(keyword.current_rank).to eq(5)
      end
    end

    context "when there are no rank histories" do
      it "returns nil" do
        expect(keyword.current_rank).to be_nil
      end
    end
  end

  describe "#rank_change" do
    let(:keyword) { create(:keyword) }

    context "when there are ranks for today and yesterday" do
      before do
        create(:rank_history, keyword: keyword, rank: 10, checked_at: Date.current - 1.day)
        create(:rank_history, keyword: keyword, rank: 5, checked_at: Date.current)
      end

      it "returns the positive change (improvement)" do
        expect(keyword.rank_change).to eq(5)
      end
    end

    context "when rank declined" do
      before do
        create(:rank_history, keyword: keyword, rank: 5, checked_at: Date.current - 1.day)
        create(:rank_history, keyword: keyword, rank: 10, checked_at: Date.current)
      end

      it "returns the negative change (decline)" do
        expect(keyword.rank_change).to eq(-5)
      end
    end

    context "when missing yesterday's rank" do
      before do
        create(:rank_history, keyword: keyword, rank: 5, checked_at: Date.current)
      end

      it "returns nil" do
        expect(keyword.rank_change).to be_nil
      end
    end
  end

  describe "#rank_trend" do
    let(:keyword) { create(:keyword) }

    context "when rank improved over 30 days" do
      before do
        create(:rank_history, keyword: keyword, rank: 20, checked_at: 25.days.ago)
        create(:rank_history, keyword: keyword, rank: 10, checked_at: Date.current)
      end

      it "returns :improving" do
        expect(keyword.rank_trend).to eq(:improving)
      end
    end

    context "when rank declined over 30 days" do
      before do
        create(:rank_history, keyword: keyword, rank: 10, checked_at: 25.days.ago)
        create(:rank_history, keyword: keyword, rank: 20, checked_at: Date.current)
      end

      it "returns :declining" do
        expect(keyword.rank_trend).to eq(:declining)
      end
    end

    context "when not enough data" do
      it "returns :unknown" do
        expect(keyword.rank_trend).to eq(:unknown)
      end
    end
  end
end
