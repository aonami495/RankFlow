# frozen_string_literal: true

class Competitor < ApplicationRecord
  belongs_to :site
  has_many :competitor_rank_histories, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :url, uniqueness: { scope: :site_id, message: "is already registered as a competitor" }

  # Returns current rank for a keyword using preloaded data if available
  def current_rank_for(keyword)
    if competitor_rank_histories.loaded?
      competitor_rank_histories
        .select { |h| h.keyword_id == keyword.id }
        .max_by(&:checked_at)&.rank
    else
      competitor_rank_histories
        .where(keyword: keyword)
        .order(checked_at: :desc)
        .first&.rank
    end
  end

  # Returns rank change for a keyword using preloaded data if available
  def rank_change_for(keyword)
    today_date = Date.current
    yesterday_date = today_date - 1.day

    if competitor_rank_histories.loaded?
      histories = competitor_rank_histories.select { |h| h.keyword_id == keyword.id }
      today = histories.find { |h| h.checked_at == today_date }
      yesterday = histories.find { |h| h.checked_at == yesterday_date }
    else
      today = competitor_rank_histories.find_by(keyword: keyword, checked_at: today_date)
      yesterday = competitor_rank_histories.find_by(keyword: keyword, checked_at: yesterday_date)
    end

    return nil unless today && yesterday

    yesterday.rank - today.rank
  end

  def average_rank(date = Date.current)
    ranks = competitor_rank_histories
              .where(checked_at: date)
              .where("rank <= 100")
              .pluck(:rank)

    return nil if ranks.empty?

    (ranks.sum.to_f / ranks.size).round(1)
  end

  def domain
    URI.parse(url).host
  rescue URI::InvalidURIError
    url
  end
end
