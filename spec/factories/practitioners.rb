FactoryBot.define do
  factory :practitioner do
    sequence(:name) { |n| "Practitioner #{n}" }
    sequence(:email) { |n| "practitioner#{n}@example.com" }
    time_zone { "UTC" }
  end
end
