# frozen_string_literal: true

class AlertGeneratorService
  RANK_DROP_THRESHOLD = 5
  RANK_RISE_THRESHOLD = 5
  TOP_10_THRESHOLD = 10

  def self.generate_for_keyword(keyword)
    new(keyword).generate
  end

  def initialize(keyword)
    @keyword = keyword
    @user = keyword.site.user
  end

  def generate
    check_rank_drop
    check_rank_rise
    check_goal_achieved
    check_rewrite_recommended
  end

  private

  def check_rank_drop
    change = @keyword.rank_change
    return unless change && change < -RANK_DROP_THRESHOLD

    create_alert(
      alert_type: "rank_drop",
      message: "#{@keyword.word} dropped #{change.abs} positions to rank #{@keyword.current_rank}"
    )
  end

  def check_rank_rise
    change = @keyword.rank_change
    return unless change && change > RANK_RISE_THRESHOLD

    create_alert(
      alert_type: "rank_rise",
      message: "#{@keyword.word} rose #{change} positions to rank #{@keyword.current_rank}"
    )
  end

  def check_goal_achieved
    current = @keyword.current_rank
    previous = previous_rank

    return unless current && previous
    return unless previous > TOP_10_THRESHOLD && current <= TOP_10_THRESHOLD

    create_alert(
      alert_type: "goal_achieved",
      message: "#{@keyword.word} reached top 10! Now at rank #{current}"
    )
  end

  def check_rewrite_recommended
    return unless @keyword.article.present?

    article = @keyword.article
    return unless article.needs_rewrite?

    existing = @user.alerts.where(
      alertable: article,
      alert_type: "rewrite_recommended"
    ).where("triggered_at > ?", 7.days.ago).exists?

    return if existing

    create_alert(
      alert_type: "rewrite_recommended",
      message: "Article '#{article.title}' has keywords with significant rank drops. Consider updating the content.",
      alertable: article
    )
  end

  def previous_rank
    yesterday = @keyword.rank_histories.find_by(checked_at: Date.current - 1.day)
    yesterday&.rank
  end

  def create_alert(alert_type:, message:, alertable: nil)
    @user.alerts.create!(
      alertable: alertable || @keyword,
      alert_type: alert_type,
      message: message,
      triggered_at: Time.current
    )
  end
end
