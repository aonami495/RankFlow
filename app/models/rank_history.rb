# frozen_string_literal: true

class RankHistory < ApplicationRecord
  belongs_to :keyword

  STATUSES = %w[success failed rate_limited network_error api_error pending].freeze

  validates :rank, presence: true, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: 101
  }, if: :success?
  validates :rank, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 101
  }, unless: :success?
  validates :checked_at, presence: true
  validates :checked_at, uniqueness: { scope: :keyword_id }
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :ranked, -> { where("rank <= 100") }
  scope :out_of_range, -> { where(rank: 101) }
  scope :recent, -> { order(checked_at: :desc) }
  scope :for_date, ->(date) { where(checked_at: date) }
  scope :last_n_days, ->(n) { where("checked_at >= ?", n.days.ago) }
  scope :successful, -> { where(status: "success") }
  scope :failed, -> { where.not(status: "success") }

  def success?
    status == "success"
  end

  def failed?
    !success?
  end

  def ranked?
    success? && rank <= 100
  end

  def out_of_range?
    success? && rank == 101
  end

  def status_label
    case status
    when "success" then "成功"
    when "failed" then "失敗"
    when "rate_limited" then "API制限"
    when "network_error" then "通信エラー"
    when "api_error" then "APIエラー"
    when "pending" then "処理中"
    else status.humanize
    end
  end

  def status_color
    case status
    when "success" then "green"
    when "rate_limited" then "yellow"
    when "pending" then "gray"
    else "red"
    end
  end

  # Create a failed record for tracking purposes
  def self.record_failure(keyword:, checked_at:, status:, error_message:)
    create!(
      keyword: keyword,
      rank: 0, # Use 0 to indicate no rank data
      checked_at: checked_at,
      status: status.to_s,
      error_message: error_message
    )
  end
end
