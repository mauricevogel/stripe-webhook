class Subscription < ApplicationRecord
  enum :state, {
    unpaid: 0,
    paid: 1,
    canceled: 2
  }, validate: true

  validates :stripe_id, uniqueness: true
  validates :stripe_customer_id, presence: true, if: :stripe_id?
  validates :paid_at, presence: true, if: :paid?
  validates :canceled_at, presence: true, if: :canceled?
end
