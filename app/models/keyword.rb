# frozen_string_literal: true

class Keyword < ApplicationRecord
  belongs_to :site
  belongs_to :article, optional: true
  has_many :rank_histories, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy

  validates :word, presence: true, length: { maximum: 100 }
  validates :word, uniqueness: { scope: :site_id, message: "has already been added to this site" }
  validates :target_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true

  scope :with_latest_rank, -> {
    left_joins(:rank_histories)
      .select("keywords.*, rank_histories.rank as latest_rank, rank_histories.checked_at")
      .where("rank_histories.checked_at = (
        SELECT MAX(rh.checked_at) FROM rank_histories rh WHERE rh.keyword_id = keywords.id
      ) OR rank_histories.id IS NULL")
  }

  # Returns current rank using preloaded data if available
  def current_rank
    if rank_histories.loaded?
      rank_histories.max_by(&:checked_at)&.rank
    else
      rank_histories.order(checked_at: :desc).first&.rank
    end
  end

  # Returns rank change using preloaded data if available
  def rank_change
    today = Date.current
    yesterday = today - 1.day

    if rank_histories.loaded?
      today_record = rank_histories.find { |h| h.checked_at == today }
      yesterday_record = rank_histories.find { |h| h.checked_at == yesterday }
    else
      today_record = rank_histories.find_by(checked_at: today)
      yesterday_record = rank_histories.find_by(checked_at: yesterday)
    end

    return nil unless today_record && yesterday_record

    yesterday_record.rank - today_record.rank
  end

  def rank_history_30days
    rank_histories.where("checked_at >= ?", 30.days.ago)
                  .order(checked_at: :asc)
  end

  def rank_trend
    history = rank_history_30days.pluck(:checked_at, :rank)
    return :unknown if history.size < 2

    first_rank = history.first[1]
    last_rank = history.last[1]

    if last_rank < first_rank
      :improving
    elsif last_rank > first_rank
      :declining
    else
      :stable
    end
  end

  # Returns the latest rank history record
  def latest_rank_history
    if rank_histories.loaded?
      rank_histories.max_by(&:checked_at)
    else
      rank_histories.order(checked_at: :desc).first
    end
  end

  # Check if the latest rank check failed
  def last_check_failed?
    latest = latest_rank_history
    latest && latest.failed?
  end

  # Get the error message from the last failed check
  def last_error_message
    latest = latest_rank_history
    return nil unless latest&.failed?

    latest.error_message
  end

  # Get the status of the last rank check
  def last_check_status
    latest = latest_rank_history
    return :pending unless latest

    latest.status.to_sym
  end

  # Check if there was a failure today
  def failed_today?
    today_record = rank_histories.find_by(checked_at: Date.current)
    today_record&.failed? || false
  end
end
