FactoryBot.define do
  factory :appointment do
    association :practitioner
    association :customer
    starts_at { 3.days.from_now }
    status { :confirmed }

    trait :past do
      starts_at { 2.days.ago }
      status { :completed }
    end

    trait :soon do
      starts_at { 24.hours.from_now }
    end

    trait :within_48h do
      starts_at { 24.hours.from_now }
    end

    trait :beyond_48h do
      starts_at { 4.days.from_now }
    end

    trait :cancelled do
      status { :cancelled }
      cancelled_at { 1.hour.ago }
    end

    trait :completed do
      starts_at { 1.day.ago }
      status { :completed }
    end

    trait :no_show do
      starts_at { 1.day.ago }
      status { :no_show }
    end
  end
end
