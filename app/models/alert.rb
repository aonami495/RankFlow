# frozen_string_literal: true

class Alert < ApplicationRecord
  belongs_to :user
  belongs_to :alertable, polymorphic: true

  ALERT_TYPES = %w[
    rank_drop
    rank_rise
    goal_achieved
    rewrite_recommended
  ].freeze

  validates :alert_type, presence: true, inclusion: { in: ALERT_TYPES }
  validates :message, presence: true
  validates :triggered_at, presence: true

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(triggered_at: :desc) }
  scope :today, -> { where("triggered_at >= ?", Date.current.beginning_of_day) }

  def mark_as_read!
    update!(read: true)
  end

  def alert_icon
    case alert_type
    when "rank_drop"
      "arrow-down"
    when "rank_rise"
      "arrow-up"
    when "goal_achieved"
      "check-circle"
    when "rewrite_recommended"
      "pencil"
    else
      "bell"
    end
  end

  def alert_color
    case alert_type
    when "rank_drop"
      "red"
    when "rank_rise"
      "green"
    when "goal_achieved"
      "teal"
    when "rewrite_recommended"
      "yellow"
    else
      "gray"
    end
  end

  def alert_label
    case alert_type
    when "rank_drop" then "Rank Drop"
    when "rank_rise" then "Rank Rise"
    when "goal_achieved" then "Goal Achieved"
    when "rewrite_recommended" then "Rewrite Recommended"
    else alert_type.humanize
    end
  end
end
