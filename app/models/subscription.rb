class Subscription < ApplicationRecord
  # Instance methods will be defined by the state machine, thus we disable the generation of them here
  enum :state, { unpaid: 0, paid: 1, canceled: 2 }, validate: true, _instance_methods: false

  validates :stripe_id, uniqueness: true
  validates :stripe_customer_id, presence: true, if: :stripe_id?
  validates :paid_at, presence: true, if: :paid?
  validates :canceled_at, presence: true, if: :canceled?

  state_machine :state, initial: :unpaid do
    event :pay do
      transition unpaid: :paid
    end

    event :cancel do
      transition paid: :canceled
    end

    before_transition do |subscription, transition|
      subscription.send(:"#{transition.to}_at=", Time.zone.now)
    end
  end
end
