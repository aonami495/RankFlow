# frozen_string_literal: true

FactoryBot.define do
  factory :article_revenue do
    article
    asp_name { Revenue::ASP_OPTIONS.sample }
    amount { rand(100..5000) }
    month { Date.current.beginning_of_month }
  end
end
