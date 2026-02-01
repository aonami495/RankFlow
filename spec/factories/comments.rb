# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    user
    content { "This is a test comment" }
    association :commentable, factory: :keyword
  end
end
