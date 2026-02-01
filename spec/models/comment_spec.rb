# frozen_string_literal: true

require "rails_helper"

RSpec.describe Comment, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:commentable) }
  end

  describe "validations" do
    it { should validate_presence_of(:content) }
    it { should validate_length_of(:content).is_at_most(1000) }
  end

  describe "scopes" do
    let(:keyword) { create(:keyword) }

    before do
      create(:comment, commentable: keyword, created_at: 2.days.ago)
      create(:comment, commentable: keyword, created_at: 1.day.ago)
      create(:comment, commentable: keyword, created_at: Time.current)
    end

    describe ".recent" do
      it "orders by created_at desc" do
        comments = keyword.comments.recent
        expect(comments.first.created_at).to be > comments.last.created_at
      end
    end

    describe ".oldest_first" do
      it "orders by created_at asc" do
        comments = keyword.comments.oldest_first
        expect(comments.first.created_at).to be < comments.last.created_at
      end
    end
  end

  describe "instance methods" do
    describe "#author_name" do
      it "returns user name" do
        user = create(:user, name: "Test User")
        comment = create(:comment, user: user)
        expect(comment.author_name).to eq("Test User")
      end
    end

    describe "#editable_by?" do
      let(:user) { create(:user) }
      let(:other_user) { create(:user) }
      let(:comment) { create(:comment, user: user) }

      it "returns true for comment owner" do
        expect(comment.editable_by?(user)).to be true
      end

      it "returns false for other user" do
        expect(comment.editable_by?(other_user)).to be false
      end

      it "returns false for nil user" do
        expect(comment.editable_by?(nil)).to be false
      end
    end
  end
end
