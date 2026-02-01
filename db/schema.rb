# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_02_01_060100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "alerts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "alertable_type", null: false
    t.bigint "alertable_id", null: false
    t.string "alert_type", null: false
    t.text "message"
    t.boolean "read", default: false, null: false
    t.datetime "triggered_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["alertable_type", "alertable_id"], name: "index_alerts_on_alertable"
    t.index ["user_id", "read", "triggered_at"], name: "index_alerts_on_user_id_and_read_and_triggered_at"
    t.index ["user_id"], name: "index_alerts_on_user_id"
  end

  create_table "article_revenues", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.string "asp_name"
    t.decimal "amount"
    t.date "month"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_article_revenues_on_article_id"
  end

  create_table "articles", force: :cascade do |t|
    t.bigint "site_id", null: false
    t.string "title"
    t.string "url"
    t.string "status"
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id"], name: "index_articles_on_site_id"
  end

  create_table "asp_connections", force: :cascade do |t|
    t.bigint "site_id", null: false
    t.string "asp_name", null: false
    t.string "api_key_encrypted"
    t.string "api_secret_encrypted"
    t.string "status", default: "pending", null: false
    t.datetime "last_synced_at"
    t.text "sync_error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id", "asp_name"], name: "index_asp_connections_on_site_id_and_asp_name", unique: true
    t.index ["site_id"], name: "index_asp_connections_on_site_id"
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "commentable_type", null: false
    t.bigint "commentable_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "competitor_rank_histories", force: :cascade do |t|
    t.bigint "competitor_id", null: false
    t.bigint "keyword_id", null: false
    t.integer "rank", null: false
    t.date "checked_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["competitor_id", "keyword_id", "checked_at"], name: "idx_competitor_rank_unique", unique: true
    t.index ["competitor_id"], name: "index_competitor_rank_histories_on_competitor_id"
    t.index ["keyword_id"], name: "index_competitor_rank_histories_on_keyword_id"
  end

  create_table "competitors", force: :cascade do |t|
    t.bigint "site_id", null: false
    t.string "name", null: false
    t.string "url", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id", "url"], name: "index_competitors_on_site_id_and_url", unique: true
    t.index ["site_id"], name: "index_competitors_on_site_id"
  end

  create_table "keywords", force: :cascade do |t|
    t.bigint "site_id", null: false
    t.string "word", null: false
    t.string "target_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "article_id"
    t.index ["article_id"], name: "index_keywords_on_article_id"
    t.index ["site_id", "word"], name: "index_keywords_on_site_id_and_word", unique: true
    t.index ["site_id"], name: "index_keywords_on_site_id"
  end

  create_table "rank_histories", force: :cascade do |t|
    t.bigint "keyword_id", null: false
    t.integer "rank", null: false
    t.date "checked_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "success", null: false
    t.text "error_message"
    t.index ["keyword_id", "checked_at"], name: "index_rank_histories_on_keyword_id_and_checked_at", unique: true
    t.index ["keyword_id"], name: "index_rank_histories_on_keyword_id"
    t.index ["status"], name: "index_rank_histories_on_status"
  end

  create_table "revenues", force: :cascade do |t|
    t.bigint "site_id", null: false
    t.string "asp_name", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.date "month", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id", "asp_name", "month"], name: "index_revenues_on_site_id_and_asp_name_and_month", unique: true
    t.index ["site_id"], name: "index_revenues_on_site_id"
  end

  create_table "sites", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "url", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "created_at"], name: "index_sites_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_sites_on_user_id"
  end

  create_table "team_memberships", force: :cascade do |t|
    t.bigint "site_id", null: false
    t.bigint "user_id", null: false
    t.string "role", default: "viewer", null: false
    t.integer "invited_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id", "user_id"], name: "index_team_memberships_on_site_id_and_user_id", unique: true
    t.index ["site_id"], name: "index_team_memberships_on_site_id"
    t.index ["user_id"], name: "index_team_memberships_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name"
    t.string "plan", default: "free"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "alerts", "users"
  add_foreign_key "article_revenues", "articles"
  add_foreign_key "articles", "sites"
  add_foreign_key "asp_connections", "sites"
  add_foreign_key "comments", "users"
  add_foreign_key "competitor_rank_histories", "competitors"
  add_foreign_key "competitor_rank_histories", "keywords"
  add_foreign_key "competitors", "sites"
  add_foreign_key "keywords", "articles"
  add_foreign_key "keywords", "sites"
  add_foreign_key "rank_histories", "keywords"
  add_foreign_key "revenues", "sites"
  add_foreign_key "sites", "users"
  add_foreign_key "team_memberships", "sites"
  add_foreign_key "team_memberships", "users"
  add_foreign_key "team_memberships", "users", column: "invited_by_id"
end
