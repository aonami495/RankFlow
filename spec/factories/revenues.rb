# frozen_string_literal: true

FactoryBot.define do
  factory :revenue do
    site
    asp_name { Revenue::ASP_OPTIONS.sample }
    amount { rand(1000..50000) }
    month { Date.current.beginning_of_month }
  end
end
