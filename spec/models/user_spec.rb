# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:plan) }
    it { is_expected.to validate_inclusion_of(:plan).in_array(%w[free basic pro]) }
  end

  describe "associations" do
    it { is_expected.to have_many(:sites).dependent(:destroy) }
    it { is_expected.to have_many(:alerts).dependent(:destroy) }
  end

  describe "#max_sites" do
    it "returns 1 for free plan" do
      user = build(:user, plan: "free")
      expect(user.max_sites).to eq(1)
    end

    it "returns 3 for basic plan" do
      user = build(:user, plan: "basic")
      expect(user.max_sites).to eq(3)
    end

    it "returns 10 for pro plan" do
      user = build(:user, plan: "pro")
      expect(user.max_sites).to eq(10)
    end
  end

  describe "#can_add_site?" do
    it "returns true when under limit" do
      user = create(:user, plan: "free")
      expect(user.can_add_site?).to be true
    end

    it "returns false when at limit" do
      user = create(:user, plan: "free")
      create(:site, user: user)
      expect(user.can_add_site?).to be false
    end
  end
end
