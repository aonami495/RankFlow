# frozen_string_literal: true

class AlertsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_alert, only: [:show, :mark_as_read]

  def index
    @alerts = current_user.alerts.recent.page(params[:page]).per(20)
    @unread_count = current_user.alerts.unread.count
  end

  def show
    @alert.mark_as_read!
    redirect_to alert_target_path
  end

  def mark_as_read
    @alert.mark_as_read!
    respond_to do |format|
      format.html { redirect_back(fallback_location: alerts_path) }
      format.turbo_stream
    end
  end

  def mark_all_as_read
    current_user.alerts.unread.update_all(read: true)
    redirect_to alerts_path, notice: "All alerts marked as read."
  end

  private

  def set_alert
    @alert = current_user.alerts.find(params[:id])
  end

  def alert_target_path
    case @alert.alertable_type
    when "Keyword"
      keyword = @alert.alertable
      site_path(keyword.site)
    when "Article"
      article = @alert.alertable
      site_article_path(article.site, article)
    when "Site"
      site_path(@alert.alertable)
    else
      alerts_path
    end
  end
end
