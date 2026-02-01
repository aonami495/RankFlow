# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    name { Faker::Name.name }
    plan { "free" }

    trait :basic do
      plan { "basic" }
    end

    trait :pro do
      plan { "pro" }
    end
  end
end
