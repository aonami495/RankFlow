# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @sites = current_user.sites.includes(:keywords)
    @current_site = @sites.find_by(id: params[:site_id]) || @sites.first

    if @current_site
      @rank_chart_data = build_rank_chart_data
      @revenue_chart_data = build_revenue_chart_data
      @failed_keywords_count = @current_site.failed_keywords_count
    end
  end

  private

  def build_rank_chart_data
    return {} unless @current_site

    @current_site.keywords.includes(:rank_histories).map do |keyword|
      data = keyword.rank_histories
                    .where("checked_at >= ?", 30.days.ago)
                    .order(checked_at: :asc)
                    .pluck(:checked_at, :rank)
                    .to_h

      { name: keyword.word, data: data }
    end
  end

  def build_revenue_chart_data
    return {} unless @current_site

    @current_site.revenues
                 .where("month >= ?", 6.months.ago.beginning_of_month)
                 .group(:month)
                 .sum(:amount)
  end
end
