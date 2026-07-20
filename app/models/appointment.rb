class Appointment < ApplicationRecord
  belongs_to :practitioner
  belongs_to :customer
  has_one :payment, dependent: :destroy

  enum :status, { confirmed: 0, completed: 1, no_show: 2 }

  validates :starts_at, presence: true
end
