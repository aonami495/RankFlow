# frozen_string_literal: true

class ReportGeneratorService
  def initialize(site, month)
    @site = site
    @month = month.beginning_of_month
    @keywords = preload_keywords_with_histories
  end

  def generate
    # Calculate keyword status first (sets @keywords_improved, etc.)
    calculate_keywords_status

    {
      average_rank: calculate_average_rank,
      rank_change: calculate_rank_change,
      keywords_improved: @keywords_improved,
      keywords_declined: @keywords_declined,
      keywords_stable: @keywords_stable,
      current_month_revenue: calculate_current_month_revenue,
      revenue_change_percent: calculate_revenue_change_percent,
      top_improving: find_top_improving_keywords,
      rank_trend: build_rank_trend,
      revenue_trend: build_revenue_trend
    }
  end

  private

  def preload_keywords_with_histories
    @site.keywords.includes(:rank_histories)
  end

  def current_month_range
    @current_month_range ||= @month..@month.end_of_month
  end

  def last_month_range
    @last_month_range ||= (@month - 1.month)...@month
  end

  def calculate_average_rank
    ranks = collect_ranks_in_range(current_month_range)
    return nil if ranks.empty?

    (ranks.sum.to_f / ranks.size).round(1)
  end

  def calculate_rank_change
    current_avg = calculate_average_rank
    return nil unless current_avg

    last_month_ranks = collect_ranks_in_range(last_month_range)
    return nil if last_month_ranks.empty?

    last_month_avg = (last_month_ranks.sum.to_f / last_month_ranks.size).round(1)
    (last_month_avg - current_avg).round(1)
  end

  def collect_ranks_in_range(range)
    @keywords.flat_map do |keyword|
      keyword.rank_histories
             .select { |h| range.cover?(h.checked_at) && h.rank <= 100 }
             .map(&:rank)
    end
  end

  def calculate_keywords_status
    @keywords_improved = 0
    @keywords_declined = 0
    @keywords_stable = 0

    month_end = @month.end_of_month
    month_start = @month

    @keywords.each do |keyword|
      histories = keyword.rank_histories.sort_by(&:checked_at)

      current = histories.find { |h| h.checked_at == month_end }&.rank
      previous = histories.find { |h| h.checked_at == month_start }&.rank

      next unless current && previous

      if current < previous
        @keywords_improved += 1
      elsif current > previous
        @keywords_declined += 1
      else
        @keywords_stable += 1
      end
    end
  end

  def calculate_current_month_revenue
    @current_month_revenue ||= @site.revenues.by_month(@month).sum(:amount)
  end

  def calculate_revenue_change_percent
    last_month_revenue = @site.revenues.by_month(@month - 1.month).sum(:amount)
    return nil unless last_month_revenue > 0

    ((calculate_current_month_revenue - last_month_revenue) / last_month_revenue * 100).round(1)
  end

  def find_top_improving_keywords
    month_start = @month
    month_end = @month.end_of_month
    start_range = month_start...(month_start + 7.days)
    end_range = (month_end - 7.days)..month_end

    @keywords.filter_map do |keyword|
      histories = keyword.rank_histories.sort_by(&:checked_at)

      start_rank = histories.find { |h| start_range.cover?(h.checked_at) }&.rank
      end_rank = histories.reverse.find { |h| end_range.cover?(h.checked_at) }&.rank

      next unless start_rank && end_rank && start_rank <= 100 && end_rank <= 100

      change = start_rank - end_rank
      next unless change > 0

      { keyword: keyword, start_rank: start_rank, end_rank: end_rank, change: change }
    end.sort_by { |d| -d[:change] }.first(5)
  end

  def build_rank_trend
    trend = {}
    6.times do |i|
      month = @month - i.months
      range = month.beginning_of_month..month.end_of_month
      ranks = collect_ranks_in_range(range)

      trend[month.strftime("%Y/%m")] = ranks.any? ? (ranks.sum.to_f / ranks.size).round(1) : nil
    end

    trend.compact.to_a.reverse.to_h
  end

  def build_revenue_trend
    @site.revenues.monthly_totals(months: 6)
         .transform_keys { |k| k.strftime("%Y/%m") }
  end
end
