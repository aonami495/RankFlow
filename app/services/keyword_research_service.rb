# frozen_string_literal: true

class KeywordResearchService
  # In production, this would integrate with Google Keyword Planner API
  # or similar services. For now, we use mock data.

  DIFFICULTY_LEVELS = %w[Low Medium High].freeze

  def self.search(query)
    new(query).search
  end

  def initialize(query)
    @query = query.downcase.strip
  end

  def search
    {
      main_keyword: analyze_keyword(@query),
      related_keywords: generate_related_keywords,
      long_tail_keywords: generate_long_tail_keywords
    }
  end

  private

  def analyze_keyword(keyword)
    {
      keyword: keyword,
      search_volume: estimate_search_volume(keyword),
      difficulty: estimate_difficulty(keyword),
      cpc: estimate_cpc(keyword),
      trend: estimate_trend
    }
  end

  def generate_related_keywords
    prefixes = ["best", "top", "how to", "what is", ""]
    suffixes = ["guide", "tips", "tutorial", "examples", "2024", "free", ""]

    related = []

    prefixes.sample(3).each do |prefix|
      suffixes.sample(2).each do |suffix|
        keyword = [prefix, @query, suffix].reject(&:blank?).join(" ")
        next if keyword == @query

        related << analyze_keyword(keyword)
      end
    end

    related.uniq { |k| k[:keyword] }.first(8)
  end

  def generate_long_tail_keywords
    templates = [
      "#{@query} for beginners",
      "#{@query} vs alternative",
      "how to use #{@query}",
      "#{@query} step by step",
      "#{@query} complete guide",
      "#{@query} best practices",
      "why #{@query} is important",
      "#{@query} mistakes to avoid"
    ]

    templates.sample(5).map { |kw| analyze_keyword(kw) }
  end

  def estimate_search_volume(keyword)
    # Mock: Generate realistic-looking search volumes
    base = keyword.length * 100
    variation = rand(500..5000)
    (base + variation).round(-2)
  end

  def estimate_difficulty(keyword)
    # Mock: Difficulty based on keyword length and common patterns
    score = rand(1..100)
    {
      score: score,
      level: case score
             when 1..33 then "Low"
             when 34..66 then "Medium"
             else "High"
             end,
      color: case score
             when 1..33 then "green"
             when 34..66 then "yellow"
             else "red"
             end
    }
  end

  def estimate_cpc(keyword)
    # Mock: CPC in JPY
    (rand(50..500) / 10.0).round(0) * 10
  end

  def estimate_trend
    # Mock: -100 to +100 (percentage change)
    rand(-30..50)
  end
end
