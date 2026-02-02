# frozen_string_literal: true

require "google_search_results"

class RankCheckerService
  def initialize(keyword_word, site_url)
    @keyword_word = keyword_word
    @site_url = normalize_url(site_url)
    @api_key = ENV["SERPAPI_KEY"]
  end

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

  private

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
end
