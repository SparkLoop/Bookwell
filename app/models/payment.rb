class Payment < ApplicationRecord
  belongs_to :appointment

  validates :amount_cents, :deposit_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
