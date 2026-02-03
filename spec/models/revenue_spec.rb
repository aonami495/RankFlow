# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Revenue, type: :model do
  let(:user) { create(:user) }
  let(:site) { create(:site, user: user) }

  describe 'associations' do
    it { should belong_to(:site) }
  end

  describe 'validations' do
    subject { build(:revenue, site: site) }

    it { should validate_presence_of(:asp_name) }
    it { should validate_presence_of(:amount) }
    it { should validate_presence_of(:month) }
    it { should validate_numericality_of(:amount).is_greater_than_or_equal_to(0) }

    describe 'uniqueness of month scoped to site_id and asp_name' do
      let!(:existing_revenue) { create(:revenue, site: site, asp_name: 'A8.net', month: Date.current.beginning_of_month) }

      it 'does not allow duplicate month for same site and asp' do
        duplicate = build(:revenue, site: site, asp_name: 'A8.net', month: Date.current.beginning_of_month)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:month]).to include('already has a record for this ASP')
      end

      it 'allows same month for different asp' do
        different_asp = build(:revenue, site: site, asp_name: 'Amazon', month: Date.current.beginning_of_month)
        expect(different_asp).to be_valid
      end

      it 'allows same month and asp for different site' do
        other_site = create(:site, user: user)
        different_site = build(:revenue, site: other_site, asp_name: 'A8.net', month: Date.current.beginning_of_month)
        expect(different_site).to be_valid
      end
    end
  end

  describe 'edge cases for amount validation' do
    it 'accepts zero amount' do
      revenue = build(:revenue, site: site, amount: 0)
      expect(revenue).to be_valid
    end

    it 'accepts very large amounts' do
      revenue = build(:revenue, site: site, amount: 999_999_999)
      expect(revenue).to be_valid
    end

    it 'rejects negative amounts' do
      revenue = build(:revenue, site: site, amount: -1)
      expect(revenue).not_to be_valid
      expect(revenue.errors[:amount]).to be_present
    end

    it 'accepts decimal amounts' do
      revenue = build(:revenue, site: site, amount: 1234.56)
      expect(revenue).to be_valid
    end

    it 'accepts amounts with small decimals (rounding test)' do
      revenue = create(:revenue, site: site, amount: 0.01)
      expect(revenue.amount.to_f).to be >= 0.01
    end
  end

  describe 'scopes' do
    let!(:current_month_revenue) { create(:revenue, site: site, amount: 10000, month: Date.current.beginning_of_month) }
    let!(:last_month_revenue) { create(:revenue, site: site, amount: 20000, month: 1.month.ago.beginning_of_month, asp_name: 'Amazon') }
    let!(:old_revenue) { create(:revenue, site: site, amount: 30000, month: 7.months.ago.beginning_of_month, asp_name: 'Rakuten') }

    describe '.by_month' do
      it 'returns revenues for the specified month' do
        results = Revenue.by_month(Date.current.beginning_of_month)
        expect(results).to include(current_month_revenue)
        expect(results).not_to include(last_month_revenue, old_revenue)
      end

      it 'returns empty when no revenues exist for the month' do
        results = Revenue.by_month(1.year.ago.beginning_of_month)
        expect(results).to be_empty
      end
    end

    describe '.recent_6months' do
      it 'includes revenues from the last 6 months' do
        results = Revenue.recent_6months
        expect(results).to include(current_month_revenue, last_month_revenue)
      end

      it 'excludes revenues older than 6 months' do
        results = Revenue.recent_6months
        expect(results).not_to include(old_revenue)
      end
    end

    describe '.by_site' do
      let(:other_site) { create(:site, user: user) }
      let!(:other_site_revenue) { create(:revenue, site: other_site, amount: 5000) }

      it 'returns revenues for the specified site only' do
        results = Revenue.by_site(site)
        expect(results).to include(current_month_revenue, last_month_revenue, old_revenue)
        expect(results).not_to include(other_site_revenue)
      end
    end
  end

  describe 'class methods' do
    let!(:revenue1) { create(:revenue, site: site, asp_name: 'A8.net', amount: 10000, month: Date.current.beginning_of_month) }
    let!(:revenue2) { create(:revenue, site: site, asp_name: 'Amazon', amount: 20000, month: Date.current.beginning_of_month) }
    let!(:revenue3) { create(:revenue, site: site, asp_name: 'A8.net', amount: 15000, month: 1.month.ago.beginning_of_month) }

    describe '.total_for_month' do
      it 'calculates the total amount for a given month' do
        total = Revenue.total_for_month(Date.current.beginning_of_month)
        expect(total).to eq(30000) # 10000 + 20000
      end

      it 'returns 0 when no revenues exist for the month' do
        total = Revenue.total_for_month(1.year.ago.beginning_of_month)
        expect(total).to eq(0)
      end

      it 'handles multiple sites correctly' do
        other_site = create(:site, user: user)
        create(:revenue, site: other_site, amount: 5000, month: Date.current.beginning_of_month)

        total = Revenue.total_for_month(Date.current.beginning_of_month)
        expect(total).to eq(35000) # 10000 + 20000 + 5000
      end
    end

    describe '.by_asp_for_month' do
      it 'groups revenues by ASP for a given month' do
        results = Revenue.by_asp_for_month(Date.current.beginning_of_month)
        expect(results['A8.net']).to eq(10000)
        expect(results['Amazon']).to eq(20000)
      end

      it 'returns empty hash when no revenues exist' do
        results = Revenue.by_asp_for_month(1.year.ago.beginning_of_month)
        expect(results).to be_empty
      end
    end

    describe '.monthly_totals' do
      before do
        # Create revenues for multiple months
        create(:revenue, site: site, amount: 5000, month: 2.months.ago.beginning_of_month, asp_name: 'Rakuten')
        create(:revenue, site: site, amount: 8000, month: 3.months.ago.beginning_of_month, asp_name: 'ValueCommerce')
      end

      it 'returns totals grouped by month' do
        results = Revenue.monthly_totals(months: 6)
        expect(results).to be_a(Hash)
        expect(results.keys.count).to be >= 3
      end

      it 'orders results by month ascending' do
        results = Revenue.monthly_totals(months: 6)
        expect(results.keys).to eq(results.keys.sort)
      end

      it 'respects the months parameter' do
        old_revenue = create(:revenue, site: site, amount: 100000, month: 8.months.ago.beginning_of_month, asp_name: 'afb')
        results = Revenue.monthly_totals(months: 6)
        expect(results.keys).not_to include(8.months.ago.beginning_of_month)
      end

      it 'sums multiple revenues in the same month' do
        results = Revenue.monthly_totals(months: 6)
        current_month_total = results[Date.current.beginning_of_month]
        expect(current_month_total).to eq(30000) # revenue1 + revenue2
      end
    end
  end

  describe 'ASP_OPTIONS constant' do
    it 'contains expected ASP providers' do
      expect(Revenue::ASP_OPTIONS).to include('A8.net', 'Amazon', 'Rakuten', 'Google AdSense')
    end

    it 'is frozen' do
      expect(Revenue::ASP_OPTIONS).to be_frozen
    end
  end
end
