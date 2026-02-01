# frozen_string_literal: true

class ArticleRevenue < ApplicationRecord
  belongs_to :article

  validates :asp_name, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :month, presence: true

  scope :by_month, ->(month) { where(month: month) }
  scope :recent_6months, -> { where("month >= ?", 6.months.ago.beginning_of_month) }
end
