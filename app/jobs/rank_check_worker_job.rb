# frozen_string_literal: true

class RankCheckWorkerJob < ApplicationJob
  queue_as :default

  # Retry on specific errors that might be transient
  retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3
  retry_on ActiveRecord::LockWaitTimeout, wait: 5.seconds, attempts: 3

  # Discard jobs for records that no longer exist
  discard_on ActiveRecord::RecordNotFound

  # Custom retry logic for rate limiting - wait longer
  sidekiq_options retry: 5 if respond_to?(:sidekiq_options)

  def perform(keyword_id)
    keyword = Keyword.find(keyword_id)
    today = Date.current

    # Skip if already checked today (success or failure already recorded)
    existing = keyword.rank_histories.find_by(checked_at: today)
    if existing
      Rails.logger.info("Rank already checked today for keyword #{keyword_id}, status: #{existing.status}")
      return
    end

    result = RankCheckerService.new(keyword.word, keyword.site.url).check_rank

    if result.success?
      handle_success(keyword, result, today)
    else
      handle_failure(keyword, result, today)
    end
  rescue RankCheckerService::RateLimitError
    # Rate limit errors should be retried without recording failure
    Rails.logger.warn("Rate limited for keyword #{keyword_id}, will retry later")
    raise
  rescue StandardError => e
    # Catch any unexpected errors and record them
    Rails.logger.error("Unexpected error in RankCheckWorkerJob for keyword #{keyword_id}: #{e.message}")
    Rails.logger.error(e.backtrace.first(10).join("\n"))

    # Record the failure if we haven't already recorded something for today
    record_unexpected_failure(keyword_id, e, Date.current) if keyword_id.present?

    # Re-raise to trigger Sidekiq retry
    raise
  end

  private

  def handle_success(keyword, result, date)
    keyword.rank_histories.create!(
      rank: result.rank,
      checked_at: date,
      status: "success"
    )

    AlertGeneratorService.generate_for_keyword(keyword)

    Rails.logger.info("Rank checked for keyword #{keyword.id}: #{result.rank}")
  end

  def handle_failure(keyword, result, date)
    # If rate limited, re-raise immediately to trigger retry (no record)
    if result.rate_limited?
      Rails.logger.warn("Rate limited for keyword #{keyword.id}, will retry")
      raise RankCheckerService::RateLimitError, result.error_message
    end

    status = result.status.to_s

    # Record the failure for non-rate-limited errors
    RankHistory.record_failure(
      keyword: keyword,
      checked_at: date,
      status: status,
      error_message: result.error_message
    )

    Rails.logger.error(
      "Failed to check rank for keyword #{keyword.id}: " \
      "status=#{status}, message=#{result.error_message}"
    )
  end

  def record_unexpected_failure(keyword_id, error, date)
    keyword = Keyword.find_by(id: keyword_id)
    return unless keyword

    # Don't create duplicate records
    return if keyword.rank_histories.exists?(checked_at: date)

    RankHistory.record_failure(
      keyword: keyword,
      checked_at: date,
      status: "failed",
      error_message: "Unexpected error: #{error.class} - #{error.message}"
    )
  rescue StandardError => e
    Rails.logger.error("Failed to record failure: #{e.message}")
  end
end
