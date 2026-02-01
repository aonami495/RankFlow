# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sites Management", type: :system do
  let(:user) { create(:user, :pro) }

  before do
    sign_in user
  end

  describe "creating a new site" do
    it "allows user to create a site from empty dashboard" do
      visit root_path

      expect(page).to have_content("No sites yet")
      click_link "Add Site"

      expect(page).to have_content("New Site")

      fill_in "Name", with: "My SEO Blog"
      fill_in "Url", with: "https://my-seo-blog.example.com"
      fill_in "Description", with: "A blog about SEO and marketing"

      click_button "Create Site"

      expect(page).to have_content("Site was successfully created")
    end

    it "allows user to create a site from sites page" do
      visit sites_path

      # Use first link since there might be two (header and empty state)
      first(:link, "Add Site").click

      fill_in "Name", with: "Test Blog"
      fill_in "Url", with: "https://test-blog.example.com"

      click_button "Create Site"

      expect(page).to have_content("Site was successfully created")
      expect(page).to have_content("Test Blog")
    end

    it "shows validation errors for invalid input" do
      visit new_site_path

      click_button "Create Site"

      expect(page).to have_content("error")
      expect(page).to have_content("Name can't be blank")
    end
  end

  describe "editing a site" do
    let!(:site) { create(:site, user: user, name: "Original Name", url: "https://original.example.com") }

    it "allows user to update site information" do
      # Go to site show page where Edit button exists
      visit site_path(site)

      click_link "Edit"

      fill_in "Name", with: "Updated Name"
      fill_in "Description", with: "Updated description"

      click_button "Update Site"

      expect(page).to have_content("Site was successfully updated")
      expect(page).to have_content("Updated Name")
    end
  end

  describe "viewing site list" do
    let!(:site1) { create(:site, user: user, name: "Blog A") }
    let!(:site2) { create(:site, user: user, name: "Blog B") }
    let!(:site3) { create(:site, user: user, name: "Blog C") }

    it "displays all user sites" do
      visit sites_path

      expect(page).to have_content("Blog A")
      expect(page).to have_content("Blog B")
      expect(page).to have_content("Blog C")
    end
  end

  describe "deleting a site" do
    let!(:site) { create(:site, user: user, name: "Site to Delete") }

    it "allows user to delete a site" do
      # Go to site show page where Delete button exists
      visit site_path(site)

      accept_confirm do
        click_button "Delete"
      end

      expect(page).to have_content("Site was successfully deleted")
      expect(page).not_to have_content("Site to Delete")
    end
  end

  describe "site detail page" do
    let!(:site) { create(:site, user: user, name: "My Test Site") }
    let!(:keyword) { create(:keyword, site: site, word: "test keyword") }

    before do
      create(:rank_history, keyword: keyword, rank: 5, checked_at: Date.current)
    end

    it "shows site details and keywords" do
      visit site_path(site)

      expect(page).to have_content("My Test Site")
      expect(page).to have_content("test keyword")
    end
  end
end
