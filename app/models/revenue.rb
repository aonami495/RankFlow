# frozen_string_literal: true

class Revenue < ApplicationRecord
  belongs_to :site

  validates :asp_name, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :month, presence: true
  validates :month, uniqueness: { scope: [:site_id, :asp_name], message: "already has a record for this ASP" }

  scope :by_month, ->(month) { where(month: month) }
  scope :recent_6months, -> { where("month >= ?", 6.months.ago.beginning_of_month) }
  scope :by_site, ->(site) { where(site: site) }

  ASP_OPTIONS = [
    "A8.net",
    "Amazon",
    "Rakuten",
    "ValueCommerce",
    "afb",
    "AccessTrade",
    "LinkShare",
    "Google AdSense",
    "Other"
  ].freeze

  def self.total_for_month(month)
    by_month(month).sum(:amount)
  end

  def self.by_asp_for_month(month)
    by_month(month).group(:asp_name).sum(:amount)
  end

  def self.monthly_totals(months: 6)
    start_month = months.months.ago.beginning_of_month
    where("month >= ?", start_month)
      .group(:month)
      .order(:month)
      .sum(:amount)
  end
end
