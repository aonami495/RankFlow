# frozen_string_literal: true

class AspConnection < ApplicationRecord
  belongs_to :site

  STATUSES = %w[pending active error disabled].freeze

  ASP_CONFIGS = {
    "Amazon" => {
      name: "Amazon Associates",
      requires_api_key: true,
      requires_api_secret: true,
      supports_auto_sync: true,
      documentation_url: "https://affiliate-program.amazon.co.jp/"
    },
    "Rakuten" => {
      name: "Rakuten Affiliate",
      requires_api_key: true,
      requires_api_secret: false,
      supports_auto_sync: true,
      documentation_url: "https://affiliate.rakuten.co.jp/"
    },
    "A8.net" => {
      name: "A8.net",
      requires_api_key: false,
      requires_api_secret: false,
      supports_auto_sync: false,
      documentation_url: "https://www.a8.net/"
    },
    "ValueCommerce" => {
      name: "ValueCommerce",
      requires_api_key: true,
      requires_api_secret: true,
      supports_auto_sync: true,
      documentation_url: "https://www.valuecommerce.ne.jp/"
    },
    "afb" => {
      name: "afb",
      requires_api_key: false,
      requires_api_secret: false,
      supports_auto_sync: false,
      documentation_url: "https://www.afi-b.com/"
    },
    "Google AdSense" => {
      name: "Google AdSense",
      requires_api_key: true,
      requires_api_secret: true,
      supports_auto_sync: true,
      documentation_url: "https://www.google.com/adsense/"
    }
  }.freeze

  validates :asp_name, presence: true, inclusion: { in: ASP_CONFIGS.keys }
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active") }
  scope :pending, -> { where(status: "pending") }
  scope :with_errors, -> { where(status: "error") }

  def asp_config
    ASP_CONFIGS[asp_name] || {}
  end

  def display_name
    asp_config[:name] || asp_name
  end

  def supports_auto_sync?
    asp_config[:supports_auto_sync] == true
  end

  def active?
    status == "active"
  end

  def sync!
    return false unless supports_auto_sync?

    result = AspSyncService.sync(self)

    if result[:success]
      update!(status: "active", last_synced_at: Time.current, sync_error: nil)
      true
    else
      update!(status: "error", sync_error: result[:error])
      false
    end
  rescue StandardError => e
    update!(status: "error", sync_error: e.message)
    false
  end

  def status_color
    case status
    when "active" then "green"
    when "pending" then "yellow"
    when "error" then "red"
    when "disabled" then "gray"
    else "gray"
    end
  end

  def status_label
    case status
    when "active" then "Connected"
    when "pending" then "Pending"
    when "error" then "Error"
    when "disabled" then "Disabled"
    else status.humanize
    end
  end
end
