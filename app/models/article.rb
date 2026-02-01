# frozen_string_literal: true

class Article < ApplicationRecord
  belongs_to :site
  has_many :keywords, dependent: :nullify
  has_many :article_revenues, dependent: :destroy

  STATUSES = %w[draft published rewrite_needed archived].freeze

  validates :title, presence: true, length: { maximum: 200 }
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :draft, -> { where(status: "draft") }
  scope :published, -> { where(status: "published") }
  scope :rewrite_needed, -> { where(status: "rewrite_needed") }
  scope :archived, -> { where(status: "archived") }
  scope :active, -> { where.not(status: "archived") }

  def status_label
    case status
    when "draft" then "Draft"
    when "published" then "Published"
    when "rewrite_needed" then "Rewrite Needed"
    when "archived" then "Archived"
    else status.humanize
    end
  end

  def status_color
    case status
    when "draft" then "gray"
    when "published" then "green"
    when "rewrite_needed" then "yellow"
    when "archived" then "red"
    else "gray"
    end
  end

  # Uses preloaded data if keywords are already loaded with rank_histories
  def average_rank
    return nil if keywords.empty?

    ranks = keywords.map(&:current_rank).compact.reject { |r| r > 100 }
    return nil if ranks.empty?

    (ranks.sum.to_f / ranks.size).round(1)
  end

  # Cached version of rewrite_priority_score for use with preloaded data
  def rewrite_priority_score_cached
    @rewrite_priority_score_cached ||= calculate_rewrite_priority_score
  end

  def total_revenue
    article_revenues.sum(:amount)
  end

  def monthly_revenue(month = Date.current.beginning_of_month)
    article_revenues.where(month: month).sum(:amount)
  end

  def needs_rewrite?
    return false if keywords.empty?

    keywords.any? do |keyword|
      change = keyword.rank_change
      change && change < -5
    end
  end

  def rewrite_priority_score
    calculate_rewrite_priority_score
  end

  private

  def calculate_rewrite_priority_score
    score = 0

    keywords.each do |keyword|
      rank = keyword.current_rank
      change = keyword.rank_change

      next unless rank && rank <= 100

      if rank <= 10
        score += 30
      elsif rank <= 20
        score += 20
      elsif rank <= 50
        score += 10
      end

      if change && change < 0
        score += change.abs * 2
      end
    end

    revenue = monthly_revenue
    score += (revenue / 1000).to_i if revenue > 0

    score
  end
end
