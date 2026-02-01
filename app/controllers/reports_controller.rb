# frozen_string_literal: true

class ReportsController < ApplicationController
  before_action :authenticate_user!

  def index
    @sites = current_user.sites
    @current_site = @sites.find_by(id: params[:site_id]) || @sites.first
    @current_month = params[:month].present? ? Date.parse(params[:month]) : Date.current.beginning_of_month

    if @current_site
      report = ReportGeneratorService.new(@current_site, @current_month).generate
      assign_report_data(report)
    else
      set_empty_report_data
    end
  end

  def show
    redirect_to reports_path(site_id: params[:site_id], month: params[:month])
  end

  private

  def assign_report_data(report)
    @average_rank = report[:average_rank]
    @rank_change = report[:rank_change]
    @keywords_improved = report[:keywords_improved]
    @keywords_declined = report[:keywords_declined]
    @keywords_stable = report[:keywords_stable]
    @current_month_revenue = report[:current_month_revenue]
    @revenue_change_percent = report[:revenue_change_percent]
    @top_improving = report[:top_improving]
    @rank_trend = report[:rank_trend]
    @revenue_trend = report[:revenue_trend]
  end

  def set_empty_report_data
    @average_rank = nil
    @rank_change = nil
    @keywords_improved = 0
    @keywords_declined = 0
    @keywords_stable = 0
    @current_month_revenue = 0
    @revenue_change_percent = nil
    @top_improving = []
    @rank_trend = {}
    @revenue_trend = {}
  end
end
