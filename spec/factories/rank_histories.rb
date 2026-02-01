# frozen_string_literal: true

FactoryBot.define do
  factory :rank_history do
    keyword
    rank { rand(1..100) }
    checked_at { Date.current }
    status { "success" }

    trait :top_10 do
      rank { rand(1..10) }
    end

    trait :out_of_range do
      rank { 101 }
    end

    trait :failed do
      rank { 0 }
      status { "failed" }
      error_message { "Test error message" }
    end

    trait :rate_limited do
      rank { 0 }
      status { "rate_limited" }
      error_message { "API rate limit exceeded" }
    end

    trait :network_error do
      rank { 0 }
      status { "network_error" }
      error_message { "Network connection failed" }
    end
  end
end
