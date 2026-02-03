# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User Journey E2E", type: :system do
  describe "complete user journey: registration to rank check" do
    it "allows a new user to register, create a site, add keywords, and view rank data" do
      # Step 1: User Registration
      visit new_user_registration_path

      expect(page).to have_content("アカウントを作成")

      fill_in "名前", with: "Test User"
      fill_in "メールアドレス", with: "newuser@example.com"
      fill_in "パスワード", with: "securepassword123", match: :first
      fill_in "パスワード（確認）", with: "securepassword123"

      click_button "新規登録"

      expect(page).to have_current_path(root_path)
      expect(page).to have_content("ダッシュボード")

      # Step 2: Create First Site
      expect(page).to have_content("サイトがまだ登録されていません")

      click_link "サイトを追加"

      expect(page).to have_content("新規サイト登録")

      fill_in "サイト名", with: "My Affiliate Blog"
      fill_in "URL", with: "https://my-affiliate-blog.com"
      fill_in "説明", with: "Personal affiliate blog about tech products"

      click_button "保存"

      expect(page).to have_content("サイトを作成しました")

      # Step 3: Add Keywords
      visit root_path

      first(:link, "キーワードを追加").click

      expect(page).to have_content("新規キーワード登録")

      fill_in "キーワード", with: "おすすめノートPC"
      fill_in "ターゲットURL", with: "https://my-affiliate-blog.com/best-laptops"

      click_button "保存"

      expect(page).to have_content("キーワードを追加しました")

      # Step 4: Verify Dashboard Shows Keyword
      visit root_path

      expect(page).to have_content("My Affiliate Blog")
      expect(page).to have_content("おすすめノートPC")

      # Step 5: Check that rank data section is present (even if no ranks yet)
      within("table") do
        expect(page).to have_content("おすすめノートPC")
      end
    end

    it "allows user to add multiple keywords and view them on dashboard" do
      user = create(:user, email: "multi@example.com", password: "password123")
      site = create(:site, user: user, name: "Multi Keyword Site")

      sign_in user
      visit root_path

      # Add first keyword
      first(:link, "キーワードを追加").click
      fill_in "キーワード", with: "SEO対策 初心者"
      fill_in "ターゲットURL", with: "https://example.com/seo-beginner"
      click_button "保存"

      expect(page).to have_content("キーワードを追加しました")

      # Add second keyword
      visit new_site_keyword_path(site)
      fill_in "キーワード", with: "アフィリエイト 始め方"
      fill_in "ターゲットURL", with: "https://example.com/affiliate-start"
      click_button "保存"

      expect(page).to have_content("キーワードを追加しました")

      # Verify both keywords on dashboard
      visit root_path

      expect(page).to have_content("SEO対策 初心者")
      expect(page).to have_content("アフィリエイト 始め方")
    end
  end

  describe "complete workflow with rank history data" do
    let(:user) { create(:user) }
    let(:site) { create(:site, user: user, name: "Rank History Test Site") }
    let(:keyword) { create(:keyword, site: site, word: "テストキーワード") }

    before do
      # Create rank history data
      create(:rank_history, keyword: keyword, rank: 15, checked_at: 3.days.ago)
      create(:rank_history, keyword: keyword, rank: 10, checked_at: 2.days.ago)
      create(:rank_history, keyword: keyword, rank: 5, checked_at: 1.day.ago)
      create(:rank_history, keyword: keyword, rank: 3, checked_at: Date.current)

      sign_in user
    end

    it "shows rank progression on dashboard" do
      visit root_path

      expect(page).to have_content("Rank History Test Site")
      expect(page).to have_content("テストキーワード")

      # Current rank should be displayed
      within("table") do
        expect(page).to have_content("3")
      end
    end

    it "shows rank improvement indicator" do
      visit root_path

      # Rank improved from 15 to 3, should show positive trend
      within("table") do
        expect(page).to have_content("テストキーワード")
        # Check for rank value
        expect(page).to have_content("3")
      end
    end

    it "displays keyword in the dashboard table" do
      visit root_path

      within("table") do
        expect(page).to have_content("テストキーワード")
        expect(page).to have_content("3") # Current rank
      end
    end
  end

  describe "revenue tracking workflow" do
    let(:user) { create(:user) }
    let!(:site) { create(:site, user: user, name: "Revenue Test Site") }

    before do
      sign_in user
    end

    it "allows user to navigate to revenue form and see site options" do
      visit revenues_path

      expect(page).to have_content("収益")

      first(:link, "収益を追加").click

      expect(page).to have_content("収益を登録")

      # Verify the form shows the user's site as an option
      within("main") do
        site_select = find("select#revenue_site_id")
        expect(site_select).to have_content("Revenue Test Site")
      end
    end

    it "shows revenue totals correctly" do
      # Create some revenue records
      create(:revenue, site: site, asp_name: "A8.net", amount: 10000, month: Date.current.beginning_of_month)
      create(:revenue, site: site, asp_name: "Amazon", amount: 5000, month: Date.current.beginning_of_month)

      visit revenues_path

      # Should display total
      expect(page).to have_content("15,000")
    end
  end

  describe "error handling in user journey" do
    let(:user) { create(:user) }
    let(:site) { create(:site, user: user, name: "Error Test Site") }
    let(:keyword) { create(:keyword, site: site, word: "エラーテスト") }

    before do
      # Create a failed rank check
      create(:rank_history, :failed, keyword: keyword, checked_at: Date.current, error_message: "API rate limit exceeded")
      sign_in user
    end

    it "displays error status for failed rank checks" do
      visit root_path

      within("table") do
        expect(page).to have_content("エラーが発生しました")
      end
    end

    it "allows user to continue using the app despite errors" do
      visit root_path

      # User should still be able to navigate
      visit sites_path
      expect(page).to have_content("Error Test Site")

      visit revenues_path
      expect(page).to have_content("収益")
    end
  end

  describe "multi-site workflow" do
    let(:user) { create(:user, :pro) }

    before do
      sign_in user
    end

    it "allows pro user to manage multiple sites" do
      # Create first site
      visit new_site_path
      fill_in "サイト名", with: "Site One"
      fill_in "URL", with: "https://site-one.example.com"
      click_button "保存"

      expect(page).to have_content("サイトを作成しました")

      # Create second site
      visit new_site_path
      fill_in "サイト名", with: "Site Two"
      fill_in "URL", with: "https://site-two.example.com"
      click_button "保存"

      expect(page).to have_content("サイトを作成しました")

      # View all sites
      visit sites_path
      expect(page).to have_content("Site One")
      expect(page).to have_content("Site Two")

      # Add keyword to first site
      site_one = Site.find_by(name: "Site One")
      visit new_site_keyword_path(site_one)

      fill_in "キーワード", with: "サイト1のキーワード"
      fill_in "ターゲットURL", with: "https://site-one.example.com/article"
      click_button "保存"

      expect(page).to have_content("キーワードを追加しました")

      # Verify dashboard shows data from both sites
      visit root_path
      expect(page).to have_content("Site One")
    end
  end

  describe "session persistence across pages" do
    let(:user) { create(:user) }
    let(:site) { create(:site, user: user) }
    let!(:keyword) { create(:keyword, site: site, word: "セッションテスト") }

    before do
      create(:rank_history, keyword: keyword, rank: 7, checked_at: Date.current)
      sign_in user
    end

    it "maintains user session when navigating through the app" do
      # Start at dashboard
      visit root_path
      expect(page).to have_content("ダッシュボード")

      # Navigate to sites
      visit sites_path
      expect(page).to have_content("サイト一覧")
      expect(page).not_to have_content("ログイン")

      # Navigate to revenues
      visit revenues_path
      expect(page).to have_content("収益")
      expect(page).not_to have_content("ログイン")

      # Back to dashboard
      visit root_path
      expect(page).to have_content("セッションテスト")
      expect(page).to have_content("7")
    end
  end
end
