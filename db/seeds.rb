# frozen_string_literal: true

# This file contains seed data for development and demo purposes
# Run with: rails db:seed

puts "🌱 Seeding database..."

# Clear existing data in development
if Rails.env.development?
  puts "  Clearing existing data..."
  [Comment, TeamMembership, CompetitorRankHistory, Competitor, Alert,
   ArticleRevenue, RankHistory, Keyword, Article, Revenue, AspConnection, Site, User].each(&:delete_all)
end

# ===========================================
# Create Test User
# ===========================================
puts "  Creating test user..."
user = User.create!(
  email: "test@example.com",
  password: "password",
  password_confirmation: "password",
  name: "田中 太郎",
  plan: "pro"
)
puts "    ✓ User: #{user.email} / password"

# ===========================================
# Site A: SEOブログ - All successful with rank variations
# ===========================================
puts "  Creating Site A (SEOブログ)..."
site_a = Site.create!(
  user: user,
  name: "SEOブログ",
  url: "https://seo-blog.example.com",
  description: "SEO対策とブログ運営について発信するサイト"
)

# Keywords for Site A with successful rank histories
keywords_a = [
  { word: "SEO 初心者", target_url: "https://seo-blog.example.com/seo-beginner" },
  { word: "ブログ 収益化", target_url: "https://seo-blog.example.com/blog-monetization" },
  { word: "アフィリエイト 始め方", target_url: "https://seo-blog.example.com/affiliate-start" },
  { word: "WordPress テーマ おすすめ", target_url: "https://seo-blog.example.com/wp-themes" },
  { word: "記事 書き方 コツ", target_url: "https://seo-blog.example.com/writing-tips" }
]

keywords_a.each_with_index do |kw_data, index|
  keyword = Keyword.create!(site: site_a, **kw_data)

  # Create 30 days of rank history with realistic variations
  base_rank = [5, 12, 8, 25, 15][index]
  30.downto(0) do |days_ago|
    date = Date.current - days_ago.days

    # Simulate gradual improvement with some fluctuation
    improvement = (30 - days_ago) / 5
    fluctuation = rand(-3..3)
    rank = [1, [base_rank - improvement + fluctuation, 101].min].max

    RankHistory.create!(
      keyword: keyword,
      rank: rank,
      checked_at: date,
      status: "success"
    )
  end
end

# Articles for Site A
3.times do |i|
  Article.create!(
    site: site_a,
    title: ["SEO対策の基本ガイド", "ブログで月5万円稼ぐ方法", "初心者向けWordPressテーマ5選"][i],
    url: "https://seo-blog.example.com/article-#{i + 1}",
    status: "published",
    published_at: (i + 1).months.ago
  )
end

# Revenue for Site A (6 months, growing trend)
asps = ["A8.net", "Amazon", "Rakuten"]
6.downto(0) do |months_ago|
  month = Date.current.beginning_of_month - months_ago.months
  base_revenue = 30000 + (6 - months_ago) * 5000 # Growing from 30k to 60k

  asps.each_with_index do |asp, index|
    multiplier = [1.0, 0.4, 0.3][index]
    amount = (base_revenue * multiplier * (0.8 + rand * 0.4)).round

    Revenue.create!(
      site: site_a,
      asp_name: asp,
      amount: amount,
      month: month
    )
  end
end

puts "    ✓ Site A: #{site_a.keywords.count} keywords, #{site_a.revenues.count} revenue records"

# ===========================================
# Site B: 副業ガイド - Some errors (for warning banner)
# ===========================================
puts "  Creating Site B (副業ガイド)..."
site_b = Site.create!(
  user: user,
  name: "副業ガイド",
  url: "https://fukugyo-guide.example.com",
  description: "サラリーマンのための副業情報サイト"
)

# Keywords for Site B with mixed status
keywords_b = [
  { word: "副業 おすすめ", status: "success", rank: 8 },
  { word: "在宅ワーク 始め方", status: "success", rank: 15 },
  { word: "クラウドソーシング 稼ぐ", status: "api_error", error: "API access denied. Check your API key permissions." },
  { word: "副業 確定申告", status: "rate_limited", error: "API rate limit exceeded. Please try again later." },
  { word: "フリーランス 税金", status: "success", rank: 22 }
]

keywords_b.each do |kw_data|
  keyword = Keyword.create!(
    site: site_b,
    word: kw_data[:word],
    target_url: "https://fukugyo-guide.example.com/#{kw_data[:word].gsub(' ', '-')}"
  )

  if kw_data[:status] == "success"
    # Create successful history for past 30 days
    30.downto(0) do |days_ago|
      date = Date.current - days_ago.days
      fluctuation = rand(-2..2)
      rank = [1, [kw_data[:rank] + fluctuation, 100].min].max

      RankHistory.create!(
        keyword: keyword,
        rank: rank,
        checked_at: date,
        status: "success"
      )
    end
  else
    # Create history with today's failure
    # Past successful data
    30.downto(1) do |days_ago|
      date = Date.current - days_ago.days
      RankHistory.create!(
        keyword: keyword,
        rank: rand(10..30),
        checked_at: date,
        status: "success"
      )
    end

    # Today's failure
    RankHistory.create!(
      keyword: keyword,
      rank: 0,
      checked_at: Date.current,
      status: kw_data[:status],
      error_message: kw_data[:error]
    )
  end
end

# Revenue for Site B (6 months, stable)
6.downto(0) do |months_ago|
  month = Date.current.beginning_of_month - months_ago.months

  Revenue.create!(
    site: site_b,
    asp_name: "A8.net",
    amount: (20000 * (0.9 + rand * 0.2)).round,
    month: month
  )
  Revenue.create!(
    site: site_b,
    asp_name: "afb",
    amount: (8000 * (0.9 + rand * 0.2)).round,
    month: month
  )
end

puts "    ✓ Site B: #{site_b.keywords.count} keywords (#{site_b.failed_keywords_count} failed today)"

# ===========================================
# Site C: 新規サイト - Pending (no rank history)
# ===========================================
puts "  Creating Site C (新規サイト)..."
site_c = Site.create!(
  user: user,
  name: "プログラミング入門",
  url: "https://programming-intro.example.com",
  description: "プログラミング初心者向けの学習サイト（立ち上げ中）"
)

# Keywords for Site C - just added, no history yet
keywords_c = [
  "Ruby 入門",
  "Rails チュートリアル",
  "JavaScript 基礎",
  "プログラミング 独学"
]

keywords_c.each do |word|
  Keyword.create!(
    site: site_c,
    word: word,
    target_url: "https://programming-intro.example.com/#{word.gsub(' ', '-')}"
  )
end

puts "    ✓ Site C: #{site_c.keywords.count} keywords (pending - no history)"

# ===========================================
# Create a competitor for Site A
# ===========================================
puts "  Creating competitors..."
competitor = Competitor.create!(
  site: site_a,
  name: "競合ブログA",
  url: "https://competitor-blog.example.com",
  notes: "主要な競合サイト"
)

# Add some competitor rank history
site_a.keywords.each do |keyword|
  15.downto(0) do |days_ago|
    date = Date.current - days_ago.days
    CompetitorRankHistory.create!(
      competitor: competitor,
      keyword: keyword,
      rank: rand(3..25),
      checked_at: date
    )
  end
end

puts "    ✓ Competitor: #{competitor.name}"

# ===========================================
# Create alerts for Site A
# ===========================================
puts "  Creating alerts..."
Alert.create!(
  user: user,
  alertable: site_a.keywords.first,
  alert_type: "rank_rise",
  message: "「SEO 初心者」が5位から3位に上昇しました！",
  triggered_at: Time.current,
  read: false
)

Alert.create!(
  user: user,
  alertable: site_a.keywords.second,
  alert_type: "rank_drop",
  message: "「ブログ 収益化」が10位から15位に下落しました",
  triggered_at: 1.day.ago,
  read: true
)

puts "    ✓ #{Alert.count} alerts created"

# ===========================================
# Summary
# ===========================================
puts ""
puts "🎉 Seeding completed!"
puts ""
puts "📊 Summary:"
puts "   Users: #{User.count}"
puts "   Sites: #{Site.count}"
puts "   Keywords: #{Keyword.count}"
puts "   Rank Histories: #{RankHistory.count}"
puts "   Revenues: #{Revenue.count}"
puts "   Alerts: #{Alert.count}"
puts ""
puts "🔐 Login credentials:"
puts "   Email: test@example.com"
puts "   Password: password"
puts ""
puts "🌐 Start the server with: bin/dev"
puts "   Then visit: http://localhost:3000"
