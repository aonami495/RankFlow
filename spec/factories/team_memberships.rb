# frozen_string_literal: true

FactoryBot.define do
  factory :team_membership do
    site
    user
    role { "viewer" }
    invited_by { nil }

    trait :owner do
      role { "owner" }
    end

    trait :editor do
      role { "editor" }
    end

    trait :viewer do
      role { "viewer" }
    end
  end
end
