# frozen_string_literal: true

FactoryBot.define do
  factory :article do
    site
    sequence(:title) { |n| "Article #{n}" }
    sequence(:url) { |n| "https://example.com/article-#{n}" }
    status { "draft" }
    published_at { nil }

    trait :published do
      status { "published" }
      published_at { 1.week.ago }
    end

    trait :rewrite_needed do
      status { "rewrite_needed" }
    end
  end
end
