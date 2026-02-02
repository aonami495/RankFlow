# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Authentication", type: :system do
  describe "user login" do
    let!(:user) { create(:user, email: "test@example.com", password: "password123") }

    it "allows user to log in with valid credentials" do
      visit new_user_session_path

      expect(page).to have_content("アカウントにログイン")
      expect(page).to have_content("RankFlowへようこそ")

      fill_in "メールアドレス", with: "test@example.com"
      fill_in "パスワード", with: "password123"
      click_button "ログイン"

      expect(page).to have_current_path(root_path)
      expect(page).to have_content("ダッシュボード")
    end

    it "shows error message with invalid credentials" do
      visit new_user_session_path

      fill_in "メールアドレス", with: "test@example.com"
      fill_in "パスワード", with: "wrongpassword"
      click_button "ログイン"

      expect(page).to have_content("メールアドレスまたはパスワードが違います")
    end

    it "redirects unauthenticated users to login page" do
      visit root_path

      expect(page).to have_current_path(new_user_session_path)
    end
  end

  describe "user session" do
    let!(:user) { create(:user) }

    it "keeps user logged in after visiting pages" do
      sign_in user
      visit root_path

      expect(page).to have_content("ダッシュボード")

      visit sites_path
      expect(page).to have_content("サイト一覧")
      expect(page).not_to have_content("ログイン")
    end
  end
end
