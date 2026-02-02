# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Revenue Management", type: :system do
  let(:user) { create(:user) }
  let!(:site) { create(:site, user: user, name: "Revenue Test Site") }
  let(:current_month) { Date.current.beginning_of_month }

  before do
    sign_in user
  end

  describe "viewing revenues list" do
    let!(:revenue1) do
      create(:revenue, site: site, asp_name: "A8.net", amount: 50000, month: current_month)
    end
    let!(:revenue2) do
      create(:revenue, site: site, asp_name: "Amazon", amount: 30000, month: current_month)
    end

    it "displays all revenue records for current month" do
      visit revenues_path

      expect(page).to have_content("A8.net")
      expect(page).to have_content("Amazon")
      expect(page).to have_content("50,000")
      expect(page).to have_content("30,000")
    end

    it "shows total revenue for the month" do
      visit revenues_path

      expect(page).to have_content("合計")
      expect(page).to have_content("80,000")
    end
  end

  describe "adding new revenue" do
    # Note: HTML5 month input has limited support in headless Chrome
    # This test validates the form structure and navigation
    it "shows the revenue creation form" do
      visit new_revenue_path

      expect(page).to have_content("収益を登録")
      expect(page).to have_select("サイト")
      expect(page).to have_select("ASP名")
      expect(page).to have_field("金額")
      expect(page).to have_css("#revenue_month")
      expect(page).to have_button("保存")
    end

    it "shows all ASP options in dropdown" do
      visit new_revenue_path

      expect(page).to have_select("ASP名", options: [
        "選択してください",
        "A8.net",
        "Amazon",
        "Rakuten",
        "ValueCommerce",
        "afb",
        "AccessTrade",
        "LinkShare",
        "Google AdSense",
        "Other"
      ])
    end
  end

  describe "editing revenue" do
    let!(:revenue) do
      create(:revenue, site: site, asp_name: "A8.net", amount: 25000, month: current_month)
    end

    it "shows the revenue edit form with existing data" do
      visit edit_revenue_path(revenue)

      expect(page).to have_content("収益を編集")
      expect(page).to have_select("サイト", selected: "Revenue Test Site")
      expect(page).to have_select("ASP名", selected: "A8.net")
      # Amount is stored as decimal, so it may show as 25000.0
      expect(find_field("金額").value).to match(/25000(\.0)?/)
      expect(page).to have_css("#revenue_month")
    end
  end

  describe "deleting revenue" do
    let!(:revenue) do
      create(:revenue, site: site, asp_name: "Rakuten", amount: 15000, month: current_month)
    end

    it "allows user to delete a revenue record" do
      visit revenues_path

      accept_confirm do
        click_button "削除"
      end

      expect(page).to have_content("収益を削除しました")
    end
  end

  describe "filtering by month" do
    let!(:revenue_current) do
      create(:revenue, site: site, asp_name: "A8.net", amount: 10000, month: current_month)
    end
    let!(:revenue_previous) do
      create(:revenue, site: site, asp_name: "Amazon", amount: 20000, month: current_month - 1.month)
    end

    it "shows only current month revenues by default" do
      visit revenues_path

      expect(page).to have_content("A8.net")
      expect(page).not_to have_content("Amazon")
    end
  end

  describe "monthly revenue chart" do
    before do
      # Create revenues for multiple months
      3.downto(0) do |months_ago|
        create(:revenue,
               site: site,
               asp_name: "A8.net",
               amount: 10000 + (months_ago * 5000),
               month: current_month - months_ago.months)
      end
    end

    it "displays the monthly revenue trend chart" do
      visit revenues_path

      expect(page).to have_content("月別収益")
      # Chart is rendered via Chartkick
      expect(page).to have_css("canvas", visible: :all)
    end
  end
end
