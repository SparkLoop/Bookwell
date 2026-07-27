FactoryBot.define do
  factory :payment do
    association :appointment
    amount_cents { 10_000 }
    deposit_cents { 2_000 }
  end
end
