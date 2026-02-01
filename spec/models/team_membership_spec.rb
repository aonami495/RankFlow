# frozen_string_literal: true

require "rails_helper"

RSpec.describe TeamMembership, type: :model do
  describe "associations" do
    it { should belong_to(:site) }
    it { should belong_to(:user) }
    it { should belong_to(:invited_by).class_name("User").optional }
  end

  describe "validations" do
    subject { build(:team_membership) }

    it { should validate_presence_of(:role) }
    it { should validate_inclusion_of(:role).in_array(TeamMembership::ROLES) }

    context "uniqueness" do
      let(:site) { create(:site) }
      let(:user) { create(:user) }

      before do
        create(:team_membership, site: site, user: user)
      end

      it "does not allow duplicate user for same site" do
        duplicate = build(:team_membership, site: site, user: user)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:user_id]).to include("is already a team member")
      end
    end
  end

  describe "scopes" do
    let(:site) { create(:site) }

    before do
      create(:team_membership, site: site, role: "owner")
      create(:team_membership, site: site, role: "editor")
      create(:team_membership, site: site, role: "viewer")
    end

    it "filters by owner" do
      expect(site.team_memberships.owners.count).to eq(1)
    end

    it "filters by editor" do
      expect(site.team_memberships.editors.count).to eq(1)
    end

    it "filters by viewer" do
      expect(site.team_memberships.viewers.count).to eq(1)
    end
  end

  describe "instance methods" do
    describe "#owner?" do
      it "returns true for owner role" do
        membership = build(:team_membership, role: "owner")
        expect(membership.owner?).to be true
      end

      it "returns false for non-owner role" do
        membership = build(:team_membership, role: "viewer")
        expect(membership.owner?).to be false
      end
    end

    describe "#can_edit?" do
      it "returns true for owner" do
        expect(build(:team_membership, role: "owner").can_edit?).to be true
      end

      it "returns true for editor" do
        expect(build(:team_membership, role: "editor").can_edit?).to be true
      end

      it "returns false for viewer" do
        expect(build(:team_membership, role: "viewer").can_edit?).to be false
      end
    end

    describe "#can_manage_team?" do
      it "returns true for owner" do
        expect(build(:team_membership, role: "owner").can_manage_team?).to be true
      end

      it "returns false for editor" do
        expect(build(:team_membership, role: "editor").can_manage_team?).to be false
      end

      it "returns false for viewer" do
        expect(build(:team_membership, role: "viewer").can_manage_team?).to be false
      end
    end

    describe "#role_label" do
      it "returns Japanese label for owner" do
        expect(build(:team_membership, role: "owner").role_label).to eq("オーナー")
      end

      it "returns Japanese label for editor" do
        expect(build(:team_membership, role: "editor").role_label).to eq("編集者")
      end

      it "returns Japanese label for viewer" do
        expect(build(:team_membership, role: "viewer").role_label).to eq("閲覧者")
      end
    end
  end
end
