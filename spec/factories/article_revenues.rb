FactoryBot.define do
  factory :article_revenue do
    article { nil }
    asp_name { "MyString" }
    amount { "9.99" }
    month { "2026-02-01" }
  end
end
