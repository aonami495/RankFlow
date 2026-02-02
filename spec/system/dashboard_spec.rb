# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Dashboard", type: :system do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "empty state" do
    it "shows empty state message when no sites exist" do
      visit root_path

      expect(page).to have_content("ダッシュボード")
      expect(page).to have_content("サイトがまだ登録されていません")
      expect(page).to have_content("最初のサイトを登録する")
      expect(page).to have_link("サイトを追加")
    end
  end

  describe "with sites and keywords" do
    let!(:site) { create(:site, user: user, name: "Test Blog") }
    let!(:keyword1) { create(:keyword, site: site, word: "SEO tips") }
    let!(:keyword2) { create(:keyword, site: site, word: "blog writing") }

    before do
      # Create successful rank history
      create(:rank_history, keyword: keyword1, rank: 5, checked_at: Date.current)
      create(:rank_history, keyword: keyword1, rank: 7, checked_at: Date.current - 1.day)
      create(:rank_history, keyword: keyword2, rank: 12, checked_at: Date.current)
    end

    it "displays site overview cards" do
      visit root_path

      expect(page).to have_content("ダッシュボード")
      expect(page).to have_content("平均順位")
      expect(page).to have_content("キーワード数")
      expect(page).to have_content("今月の収益")
    end

    it "displays keywords table with ranks" do
      visit root_path

      within("table") do
        expect(page).to have_content("SEO tips")
        expect(page).to have_content("blog writing")
        expect(page).to have_content("5")  # Current rank for keyword1
        expect(page).to have_content("12") # Current rank for keyword2
      end
    end

    it "shows rank improvement indicator" do
      visit root_path

      # keyword1 improved from 7 to 5 (change of +2)
      within("table") do
        expect(page).to have_content("2") # Rank change displayed
      end
    end

    it "allows switching between sites" do
      site2 = create(:site, user: user, name: "Second Blog")
      create(:keyword, site: site2, word: "another keyword")

      visit root_path

      expect(page).to have_select("site_id")

      select "Second Blog", from: "site_id"

      expect(page).to have_content("another keyword")
    end
  end

  describe "error warning banner" do
    let!(:site) { create(:site, user: user, name: "Error Test Site") }
    let!(:keyword1) { create(:keyword, site: site, word: "working keyword") }
    let!(:keyword2) { create(:keyword, site: site, word: "failed keyword") }
    let!(:keyword3) { create(:keyword, site: site, word: "rate limited keyword") }

    context "when some keywords have failed today" do
      before do
        # Successful keyword
        create(:rank_history, keyword: keyword1, rank: 10, checked_at: Date.current, status: "success")

        # Failed keywords
        create(:rank_history, :failed, keyword: keyword2, checked_at: Date.current,
               error_message: "API access denied")
        create(:rank_history, :rate_limited, keyword: keyword3, checked_at: Date.current,
               error_message: "Rate limit exceeded")
      end

      it "displays warning banner with failure count" do
        visit root_path

        expect(page).to have_css(".bg-yellow-50")
        expect(page).to have_content("2件")
        expect(page).to have_content("キーワードで順位取得に失敗しました")
        expect(page).to have_content("API制限または通信エラーの可能性があります")
      end

      it "shows error indicator for failed keywords in table" do
        visit root_path

        within("table") do
          # Failed keywords should show error message
          expect(page).to have_content("エラーが発生しました").twice
          # Working keyword should show rank
          expect(page).to have_content("10")
        end
      end
    end

    context "when all keywords are successful" do
      before do
        create(:rank_history, keyword: keyword1, rank: 10, checked_at: Date.current, status: "success")
        create(:rank_history, keyword: keyword2, rank: 15, checked_at: Date.current, status: "success")
        create(:rank_history, keyword: keyword3, rank: 20, checked_at: Date.current, status: "success")
      end

      it "does not display warning banner" do
        visit root_path

        expect(page).not_to have_css(".bg-yellow-50")
        expect(page).not_to have_content("キーワードで順位取得に失敗しました")
      end
    end
  end

  describe "charts" do
    let!(:site) { create(:site, user: user, name: "Chart Test Site") }
    let!(:keyword) { create(:keyword, site: site, word: "chart keyword") }

    before do
      # Create 30 days of rank history
      30.downto(0) do |days_ago|
        create(:rank_history,
               keyword: keyword,
               rank: rand(1..50),
               checked_at: Date.current - days_ago.days)
      end

      # Create 6 months of revenue
      6.downto(0) do |months_ago|
        create(:revenue,
               site: site,
               asp_name: "A8.net",
               amount: rand(10000..50000),
               month: Date.current.beginning_of_month - months_ago.months)
      end
    end

    it "displays rank trends chart" do
      visit root_path

      expect(page).to have_content("順位推移")
      # Chartkick renders a canvas element
      expect(page).to have_css("canvas", visible: :all)
    end

    it "displays revenue chart" do
      visit root_path

      expect(page).to have_content("収益推移")
    end
  end
end
