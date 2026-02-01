# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReportGeneratorService do
  let(:user) { create(:user) }
  let(:site) { create(:site, user: user) }
  let(:current_month) { Date.current.beginning_of_month }

  describe "#generate" do
    context "when site has no keywords" do
      it "returns empty report data" do
        service = described_class.new(site, current_month)
        report = service.generate

        expect(report[:average_rank]).to be_nil
        expect(report[:keywords_improved]).to eq(0)
        expect(report[:top_improving]).to be_empty
      end
    end

    context "when site has keywords with rank histories" do
      let!(:keyword1) { create(:keyword, site: site) }
      let!(:keyword2) { create(:keyword, site: site, word: "another keyword") }

      before do
        # Create rank histories for current month
        create(:rank_history, keyword: keyword1, rank: 10, checked_at: current_month)
        create(:rank_history, keyword: keyword1, rank: 8, checked_at: current_month.end_of_month)
        create(:rank_history, keyword: keyword2, rank: 20, checked_at: current_month)
        create(:rank_history, keyword: keyword2, rank: 25, checked_at: current_month.end_of_month)
      end

      it "calculates average rank correctly" do
        service = described_class.new(site, current_month)
        report = service.generate

        # Average of ranks: (10 + 8 + 20 + 25) / 4 = 15.75
        expect(report[:average_rank]).to be_a(Float)
        expect(report[:average_rank]).to be > 0
      end

      it "identifies improved and declined keywords" do
        service = described_class.new(site, current_month)
        report = service.generate

        # keyword1: 10 -> 8 (improved)
        # keyword2: 20 -> 25 (declined)
        expect(report[:keywords_improved]).to eq(1)
        expect(report[:keywords_declined]).to eq(1)
      end

      it "finds top improving keywords" do
        service = described_class.new(site, current_month)
        report = service.generate

        expect(report[:top_improving]).to be_an(Array)
      end
    end

    context "when site has revenues" do
      before do
        create(:revenue, site: site, amount: 10000, month: current_month)
        create(:revenue, site: site, amount: 5000, month: current_month, asp_name: "Amazon")
        create(:revenue, site: site, amount: 12000, month: current_month - 1.month)
      end

      it "calculates current month revenue" do
        service = described_class.new(site, current_month)
        report = service.generate

        expect(report[:current_month_revenue]).to eq(15000)
      end

      it "calculates revenue change percent" do
        service = described_class.new(site, current_month)
        report = service.generate

        # (15000 - 12000) / 12000 * 100 = 25%
        expect(report[:revenue_change_percent]).to eq(25.0)
      end

      it "builds revenue trend" do
        service = described_class.new(site, current_month)
        report = service.generate

        expect(report[:revenue_trend]).to be_a(Hash)
      end
    end
  end
end
