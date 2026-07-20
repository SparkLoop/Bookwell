class Customer < ApplicationRecord
  has_many :appointments, dependent: :destroy

  validates :name, :email, presence: true
end
