# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Keywords Management", type: :system do
  let(:user) { create(:user) }
  let!(:site) { create(:site, user: user, name: "Keyword Test Site") }

  before do
    sign_in user
  end

  describe "adding a new keyword" do
    it "allows user to add a keyword from dashboard" do
      visit root_path

      # Click the first "Add Keyword" link in the header area
      first(:link, "Add Keyword").click

      expect(page).to have_content("Add Keyword")

      fill_in "Keyword", with: "SEO best practices"
      fill_in "Target URL (optional)", with: "https://example.com/seo-guide"

      click_button "Create Keyword"

      expect(page).to have_content("Keyword was successfully added")
    end

    it "shows validation error for empty keyword" do
      visit new_site_keyword_path(site)

      click_button "Create Keyword"

      expect(page).to have_content("error")
      expect(page).to have_content("Word can't be blank")
    end
  end

  describe "viewing keywords" do
    let!(:keyword1) { create(:keyword, site: site, word: "keyword one") }
    let!(:keyword2) { create(:keyword, site: site, word: "keyword two") }

    before do
      create(:rank_history, keyword: keyword1, rank: 5, checked_at: Date.current)
      create(:rank_history, keyword: keyword2, rank: 15, checked_at: Date.current)
    end

    it "displays keywords on dashboard" do
      visit root_path

      expect(page).to have_content("keyword one")
      expect(page).to have_content("keyword two")
      expect(page).to have_content("5")
      expect(page).to have_content("15")
    end
  end

  describe "editing a keyword" do
    let!(:keyword) { create(:keyword, site: site, word: "original keyword") }

    it "allows user to edit a keyword" do
      visit root_path

      click_link "Edit"

      fill_in "Keyword", with: "updated keyword"

      click_button "Update Keyword"

      expect(page).to have_content("Keyword was successfully updated")
    end
  end

  describe "keyword with error status" do
    let!(:keyword) { create(:keyword, site: site, word: "error keyword") }

    before do
      create(:rank_history, :failed,
             keyword: keyword,
             checked_at: Date.current,
             error_message: "API access denied")
    end

    it "shows error indicator in dashboard" do
      visit root_path

      within("table") do
        expect(page).to have_content("Error")
        expect(page).to have_content("error keyword")
      end
    end
  end
end
