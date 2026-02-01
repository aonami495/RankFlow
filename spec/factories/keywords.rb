# frozen_string_literal: true

FactoryBot.define do
  factory :keyword do
    site
    sequence(:word) { |n| "keyword #{n}" }
    target_url { nil }

    trait :with_target_url do
      target_url { "https://example.com/page" }
    end
  end
end
