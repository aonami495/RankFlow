# frozen_string_literal: true

class CompetitorRankHistory < ApplicationRecord
  belongs_to :competitor
  belongs_to :keyword

  validates :rank, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 101 }
  validates :checked_at, presence: true
  validates :checked_at, uniqueness: { scope: [:competitor_id, :keyword_id] }

  scope :for_keyword, ->(keyword) { where(keyword: keyword) }
  scope :on_date, ->(date) { where(checked_at: date) }
  scope :recent, -> { order(checked_at: :desc) }
end
