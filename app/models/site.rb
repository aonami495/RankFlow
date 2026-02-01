# frozen_string_literal: true

class Site < ApplicationRecord
  belongs_to :user
  has_many :keywords, dependent: :destroy
  has_many :revenues, dependent: :destroy
  has_many :articles, dependent: :destroy
  has_many :asp_connections, dependent: :destroy
  has_many :competitors, dependent: :destroy
  has_many :team_memberships, dependent: :destroy
  has_many :team_members, through: :team_memberships, source: :user
  has_many :comments, as: :commentable, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :description, length: { maximum: 500 }

  def average_rank(date = Date.current)
    ranks = keywords.joins(:rank_histories)
                    .where(rank_histories: { checked_at: date })
                    .where("rank_histories.rank <= 100")
                    .pluck("rank_histories.rank")

    return nil if ranks.empty?

    (ranks.sum.to_f / ranks.size).round(1)
  end

  def total_revenue(month = Date.current.beginning_of_month)
    revenues.where(month: month).sum(:amount)
  end

  def keywords_count_by_rank_range
    {
      top_3: keywords_in_rank_range(1, 3),
      top_10: keywords_in_rank_range(4, 10),
      top_30: keywords_in_rank_range(11, 30),
      top_100: keywords_in_rank_range(31, 100),
      out_of_range: keywords_in_rank_range(101, 101)
    }
  end

  # Count keywords that failed to check today
  def failed_keywords_count(date = Date.current)
    keywords.joins(:rank_histories)
            .where(rank_histories: { checked_at: date })
            .where.not(rank_histories: { status: "success" })
            .count
  end

  # Check if any keywords failed today
  def has_failed_keywords?(date = Date.current)
    failed_keywords_count(date) > 0
  end

  # Get keywords that failed to check today
  def failed_keywords(date = Date.current)
    keywords.joins(:rank_histories)
            .where(rank_histories: { checked_at: date })
            .where.not(rank_histories: { status: "success" })
            .includes(:rank_histories)
  end

  private

  def keywords_in_rank_range(min, max)
    keywords.joins(:rank_histories)
            .where(rank_histories: { checked_at: Date.current })
            .where("rank_histories.rank >= ? AND rank_histories.rank <= ?", min, max)
            .count
  end
end
