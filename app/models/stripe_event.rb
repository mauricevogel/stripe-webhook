class StripeEvent < ApplicationRecord
  self.primary_key = "stripe_id"

  # Defines the list of stripe event types that we want to store and act upon
  ACTIONABLE_EVENT_TYPES = %w[
    customer.subscription.created
    customer.subscription.deleted
    invoice.paid
  ].freeze

  after_create_commit { ProcessStripeEventsJob.perform_later(self) }

  validates :stripe_id, :data, presence: true
  validates :event_type, inclusion: { in: ACTIONABLE_EVENT_TYPES }

  def readonly? = !new_record?
end
