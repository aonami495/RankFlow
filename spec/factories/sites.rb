# frozen_string_literal: true

FactoryBot.define do
  factory :site do
    user
    sequence(:name) { |n| "Site #{n}" }
    sequence(:url) { |n| "https://example#{n}.com" }
    description { Faker::Lorem.sentence }
  end
end
