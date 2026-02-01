# frozen_string_literal: true

require "google/apis/customsearch_v1"

class RankCheckerService
  MAX_RESULTS = 100
  RESULTS_PER_PAGE = 10
  MAX_RETRIES = 3
  BASE_RETRY_DELAY = 2 # seconds

  # Result object to encapsulate rank check outcome
  class Result
    attr_reader :rank, :status, :error_message

    def initialize(rank: nil, status: :success, error_message: nil)
      @rank = rank
      @status = status
      @error_message = error_message
    end

    def success?
      status == :success
    end

    def failed?
      !success?
    end

    def rate_limited?
      status == :rate_limited
    end
  end

  # Custom error classes for better error handling
  class ApiError < StandardError; end
  class RateLimitError < ApiError; end
  class NetworkError < ApiError; end
  class ConfigurationError < ApiError; end

  def initialize(keyword_word, site_url)
    @keyword_word = keyword_word
    @site_url = normalize_url(site_url)
    @client = Google::Apis::CustomsearchV1::CustomSearchAPIService.new
    @client.key = ENV["GOOGLE_API_KEY"]
    @cx = ENV["GOOGLE_SEARCH_ENGINE_ID"]
  end

  def check_rank
    return mock_result if ENV["GOOGLE_API_KEY"].blank?

    validate_configuration!

    rank = perform_rank_check
    Result.new(rank: rank, status: :success)
  rescue RateLimitError => e
    log_error("Rate limit exceeded", e)
    Result.new(status: :rate_limited, error_message: "API rate limit exceeded. Please try again later.")
  rescue NetworkError => e
    log_error("Network error", e)
    Result.new(status: :network_error, error_message: "Network connection failed: #{e.message}")
  rescue ConfigurationError => e
    log_error("Configuration error", e)
    Result.new(status: :configuration_error, error_message: e.message)
  rescue Google::Apis::ClientError => e
    handle_client_error(e)
  rescue Google::Apis::ServerError => e
    log_error("Google API server error", e)
    Result.new(status: :api_error, error_message: "Google API server error: #{e.message}")
  rescue StandardError => e
    log_error("Unexpected error", e)
    Result.new(status: :error, error_message: "Unexpected error: #{e.message}")
  end

  private

  def validate_configuration!
    raise ConfigurationError, "GOOGLE_API_KEY is not configured" if @client.key.blank?
    raise ConfigurationError, "GOOGLE_SEARCH_ENGINE_ID is not configured" if @cx.blank?
  end

  def perform_rank_check
    (1..10).each do |page|
      start_index = (page - 1) * RESULTS_PER_PAGE + 1

      results = fetch_search_results_with_retry(start_index)
      rank = find_rank_in_results(results, start_index - 1)

      return rank if rank

      # Small delay between pages to avoid rate limiting
      sleep 0.5
    end

    101 # Not found in top 100
  end

  def fetch_search_results_with_retry(start_index)
    retries = 0

    begin
      fetch_search_results(start_index)
    rescue Google::Apis::RateLimitError => e
      retries += 1
      if retries <= MAX_RETRIES
        delay = exponential_backoff_delay(retries)
        Rails.logger.warn("Rate limited, retrying in #{delay}s (attempt #{retries}/#{MAX_RETRIES})")
        sleep delay
        retry
      else
        raise RateLimitError, "Rate limit exceeded after #{MAX_RETRIES} retries: #{e.message}"
      end
    rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Net::OpenTimeout => e
      retries += 1
      if retries <= MAX_RETRIES
        delay = exponential_backoff_delay(retries)
        Rails.logger.warn("Network error, retrying in #{delay}s (attempt #{retries}/#{MAX_RETRIES})")
        sleep delay
        retry
      else
        raise NetworkError, "Network error after #{MAX_RETRIES} retries: #{e.message}"
      end
    end
  end

  def exponential_backoff_delay(retry_count)
    # Exponential backoff with jitter: 2^retry * base_delay + random jitter
    base_delay = (2**retry_count) * BASE_RETRY_DELAY
    jitter = rand(0..1000) / 1000.0 # 0-1 second jitter
    base_delay + jitter
  end

  def fetch_search_results(start_index)
    @client.list_cses(
      q: @keyword_word,
      cx: @cx,
      num: RESULTS_PER_PAGE,
      start: start_index,
      gl: "jp",
      lr: "lang_ja"
    )
  end

  def find_rank_in_results(results, offset)
    return nil unless results&.items

    results.items.each_with_index do |item, index|
      item_url = normalize_url(item.link)

      if urls_match?(item_url, @site_url)
        return offset + index + 1
      end
    end

    nil
  end

  def urls_match?(item_url, target_url)
    item_url.include?(target_url) || target_url.include?(item_url)
  end

  def normalize_url(url)
    url = url.to_s.downcase
    url = url.gsub(%r{^https?://(www\.)?}, "")
    url = url.gsub(%r{/$}, "")
    url
  end

  def handle_client_error(error)
    case error.status_code
    when 429
      log_error("Rate limit (429)", error)
      Result.new(status: :rate_limited, error_message: "API rate limit exceeded")
    when 400
      log_error("Bad request (400)", error)
      Result.new(status: :api_error, error_message: "Invalid request: #{error.message}")
    when 403
      log_error("Forbidden (403)", error)
      Result.new(status: :api_error, error_message: "API access denied. Check your API key permissions.")
    else
      log_error("Client error (#{error.status_code})", error)
      Result.new(status: :api_error, error_message: "API error: #{error.message}")
    end
  end

  def log_error(context, error)
    Rails.logger.error("[RankCheckerService] #{context}: #{error.class} - #{error.message}")
    Rails.logger.error(error.backtrace.first(5).join("\n")) if error.backtrace
  end

  def mock_result
    # For development/testing without API key
    Result.new(rank: rand(1..50), status: :success)
  end
end
