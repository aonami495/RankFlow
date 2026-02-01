# frozen_string_literal: true

class AspSyncService
  # This service would integrate with actual ASP APIs in production.
  # For now, it provides a mock implementation.

  def self.sync(asp_connection)
    new(asp_connection).sync
  end

  def initialize(asp_connection)
    @connection = asp_connection
    @site = asp_connection.site
  end

  def sync
    case @connection.asp_name
    when "Amazon"
      sync_amazon
    when "Rakuten"
      sync_rakuten
    when "Google AdSense"
      sync_adsense
    when "ValueCommerce"
      sync_valuecommerce
    else
      { success: false, error: "Auto-sync not supported for #{@connection.asp_name}" }
    end
  end

  private

  def sync_amazon
    # Mock: In production, this would use Amazon Product Advertising API
    return { success: false, error: "API key required" } if @connection.api_key_encrypted.blank?

    # Simulate API call
    mock_revenue_data.each do |data|
      create_or_update_revenue(data)
    end

    { success: true, synced_count: mock_revenue_data.count }
  end

  def sync_rakuten
    # Mock: In production, this would use Rakuten Affiliate API
    return { success: false, error: "API key required" } if @connection.api_key_encrypted.blank?

    mock_revenue_data.each do |data|
      create_or_update_revenue(data)
    end

    { success: true, synced_count: mock_revenue_data.count }
  end

  def sync_adsense
    # Mock: In production, this would use Google AdSense API
    return { success: false, error: "API credentials required" } if @connection.api_key_encrypted.blank?

    mock_revenue_data.each do |data|
      create_or_update_revenue(data)
    end

    { success: true, synced_count: mock_revenue_data.count }
  end

  def sync_valuecommerce
    # Mock: In production, this would use ValueCommerce API
    return { success: false, error: "API credentials required" } if @connection.api_key_encrypted.blank?

    mock_revenue_data.each do |data|
      create_or_update_revenue(data)
    end

    { success: true, synced_count: mock_revenue_data.count }
  end

  def mock_revenue_data
    # Generate mock revenue data for the last 3 months
    3.times.map do |i|
      month = i.months.ago.beginning_of_month
      {
        month: month,
        amount: rand(1000..50000)
      }
    end
  end

  def create_or_update_revenue(data)
    revenue = @site.revenues.find_or_initialize_by(
      asp_name: @connection.asp_name,
      month: data[:month]
    )
    revenue.amount = data[:amount]
    revenue.save!
  end
end
