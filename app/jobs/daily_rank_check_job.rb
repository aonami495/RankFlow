# frozen_string_literal: true

class DailyRankCheckJob < ApplicationJob
  queue_as :default

  def perform
    total_keywords = Keyword.count
    processed = 0

    Keyword.includes(:site).find_each do |keyword|
      RankCheckWorkerJob.perform_later(keyword.id)
      processed += 1

      if (processed % 10).zero?
        Rails.logger.info("Rank check progress: #{processed}/#{total_keywords}")
      end

      sleep 1
    end

    Rails.logger.info("Daily rank check completed: #{processed} keywords queued")
  end
end
