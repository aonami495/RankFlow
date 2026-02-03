# frozen_string_literal: true

require "google_search_results"

class RankCheckerService
  class RateLimitError < StandardError; end

  # Result object for structured response
  Result = Struct.new(:rank, :status, :error_message, keyword_init: true) do
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

  MAX_RETRIES = 3
  BASE_DELAY = 2

  def initialize(keyword_word, site_url)
    @keyword_word = keyword_word
    @site_url = normalize_url(site_url)
    @api_key = ENV["SERPAPI_KEY"]
  end

  # Original execute method for backward compatibility
  def execute
    return nil unless @api_key

    params = {
      engine: "google",
      q: @keyword_word,
      gl: "jp",
      hl: "ja",
      num: 100,
      api_key: @api_key
    }

    search = GoogleSearch.new(params)
    results = search.get_hash

    find_rank_in_results(results[:organic_results])
  rescue StandardError => e
    Rails.logger.error("SerpApi Error: #{e.message}")
    nil
  end

  # New method returning Result object for job integration
  def check_rank
    return mock_result unless @api_key

    retries = 0
    begin
      rank = execute_search
      Result.new(rank: rank, status: :success)
    rescue RateLimitError => e
      if retries < MAX_RETRIES
        retries += 1
        sleep(exponential_backoff_delay(retries))
        retry
      end
      Result.new(status: :rate_limited, error_message: "Exceeded rate limit after #{MAX_RETRIES} retries")
    rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
      if retries < MAX_RETRIES
        retries += 1
        sleep(exponential_backoff_delay(retries))
        retry
      end
      Result.new(status: :network_error, error_message: "Network error: #{e.message}")
    rescue StandardError => e
      handle_api_error(e)
    end
  end

  private

  def execute_search
    params = {
      engine: "google",
      q: @keyword_word,
      gl: "jp",
      hl: "ja",
      num: 100,
      api_key: @api_key
    }

    search = GoogleSearch.new(params)
    results = search.get_hash

    # Check for rate limit in response
    if results[:error]&.include?("rate") || results[:error]&.include?("429")
      raise RateLimitError, results[:error]
    end

    find_rank_in_results(results[:organic_results])
  end

  def handle_api_error(error)
    error_message = error.message.to_s.downcase

    if error_message.include?("rate") || error_message.include?("429")
      Result.new(status: :rate_limited, error_message: "API rate limit exceeded")
    elsif error_message.include?("forbidden") || error_message.include?("403")
      Result.new(status: :api_error, error_message: "API access denied: #{error.message}")
    elsif error_message.include?("server") || error_message.include?("500")
      Result.new(status: :api_error, error_message: "API server error: #{error.message}")
    else
      Rails.logger.error("SerpApi Error: #{error.message}")
      Result.new(status: :api_error, error_message: error.message)
    end
  end

  def mock_result
    # Return mock result when API key is not configured
    mock_rank = rand(1..50)
    Result.new(rank: mock_rank, status: :success)
  end

  def find_rank_in_results(organic_results)
    return 101 unless organic_results

    organic_results.each do |result|
      if normalize_url(result[:link]).include?(@site_url)
        return result[:position]
      end
    end

    101
  end

  def normalize_url(url)
    url.to_s.downcase.gsub(%r{^https?://(www\.)?}, "").gsub(%r{/$}, "")
  end

  def exponential_backoff_delay(retry_count)
    # Exponential backoff with jitter
    base = (2**retry_count) * BASE_DELAY
    jitter = rand(0..1000) / 1000.0
    base + jitter
  end
end
