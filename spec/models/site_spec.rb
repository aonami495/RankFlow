# frozen_string_literal: true

require "rails_helper"

RSpec.describe Site, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:url) }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }
    it { is_expected.to validate_length_of(:description).is_at_most(500) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:keywords).dependent(:destroy) }
    it { is_expected.to have_many(:revenues).dependent(:destroy) }
    it { is_expected.to have_many(:articles).dependent(:destroy) }
    it { is_expected.to have_many(:asp_connections).dependent(:destroy) }
  end

  describe "#average_rank" do
    let(:site) { create(:site) }
    let(:keyword) { create(:keyword, site: site) }

    context "when there are rank histories" do
      before do
        create(:rank_history, keyword: keyword, rank: 5, checked_at: Date.current)
      end

      it "returns the average rank" do
        expect(site.average_rank).to eq(5.0)
      end
    end

    context "when there are no rank histories" do
      it "returns nil" do
        expect(site.average_rank).to be_nil
      end
    end
  end

  describe "#total_revenue" do
    let(:site) { create(:site) }

    context "when there are revenues" do
      before do
        create(:revenue, site: site, amount: 10000, month: Date.current.beginning_of_month, asp_name: "A8.net")
        create(:revenue, site: site, amount: 5000, month: Date.current.beginning_of_month, asp_name: "Amazon")
      end

      it "returns the total revenue for the month" do
        expect(site.total_revenue).to eq(15000)
      end
    end

    context "when there are no revenues" do
      it "returns 0" do
        expect(site.total_revenue).to eq(0)
      end
    end
  end
end
