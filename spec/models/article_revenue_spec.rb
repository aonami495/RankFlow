# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ArticleRevenue, type: :model do
  let(:user) { create(:user) }
  let(:site) { create(:site, user: user) }
  let(:article) { create(:article, site: site) }

  describe 'associations' do
    it { should belong_to(:article) }
  end

  describe 'validations' do
    subject { build(:article_revenue, article: article) }

    it { should validate_presence_of(:asp_name) }
    it { should validate_presence_of(:amount) }
    it { should validate_presence_of(:month) }
    it { should validate_numericality_of(:amount).is_greater_than_or_equal_to(0) }
  end

  describe 'edge cases for amount validation' do
    it 'accepts zero amount' do
      revenue = build(:article_revenue, article: article, amount: 0)
      expect(revenue).to be_valid
    end

    it 'accepts very large amounts' do
      revenue = build(:article_revenue, article: article, amount: 999_999_999)
      expect(revenue).to be_valid
    end

    it 'rejects negative amounts' do
      revenue = build(:article_revenue, article: article, amount: -1)
      expect(revenue).not_to be_valid
      expect(revenue.errors[:amount]).to be_present
    end

    it 'accepts decimal amounts' do
      revenue = build(:article_revenue, article: article, amount: 1234.56)
      expect(revenue).to be_valid
    end

    it 'handles very small decimal amounts' do
      revenue = create(:article_revenue, article: article, amount: 0.01)
      expect(revenue.amount.to_f).to be >= 0.01
    end
  end

  describe 'scopes' do
    let!(:current_month_revenue) { create(:article_revenue, article: article, amount: 1000, month: Date.current.beginning_of_month) }
    let!(:last_month_revenue) { create(:article_revenue, article: article, amount: 2000, month: 1.month.ago.beginning_of_month) }
    let!(:old_revenue) { create(:article_revenue, article: article, amount: 3000, month: 7.months.ago.beginning_of_month) }

    describe '.by_month' do
      it 'returns revenues for the specified month' do
        results = ArticleRevenue.by_month(Date.current.beginning_of_month)
        expect(results).to include(current_month_revenue)
        expect(results).not_to include(last_month_revenue, old_revenue)
      end

      it 'returns empty when no revenues exist for the month' do
        results = ArticleRevenue.by_month(1.year.ago.beginning_of_month)
        expect(results).to be_empty
      end
    end

    describe '.recent_6months' do
      it 'includes revenues from the last 6 months' do
        results = ArticleRevenue.recent_6months
        expect(results).to include(current_month_revenue, last_month_revenue)
      end

      it 'excludes revenues older than 6 months' do
        results = ArticleRevenue.recent_6months
        expect(results).not_to include(old_revenue)
      end
    end
  end

  describe 'article relationship' do
    it 'allows multiple revenues for the same article in different months' do
      create(:article_revenue, article: article, month: Date.current.beginning_of_month)
      revenue2 = build(:article_revenue, article: article, month: 1.month.ago.beginning_of_month)
      expect(revenue2).to be_valid
    end

    it 'allows multiple ASPs for the same article and month' do
      create(:article_revenue, article: article, asp_name: 'A8.net', month: Date.current.beginning_of_month)
      revenue2 = build(:article_revenue, article: article, asp_name: 'Amazon', month: Date.current.beginning_of_month)
      expect(revenue2).to be_valid
    end
  end

  describe 'data integrity' do
    it 'is destroyed when the parent article is destroyed' do
      revenue = create(:article_revenue, article: article)
      expect { article.destroy }.to change(ArticleRevenue, :count).by(-1)
    end
  end
end
