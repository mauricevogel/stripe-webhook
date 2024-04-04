class ProcessStripeEventsJob < ApplicationJob
  queue_as :default

  def perform(stripe_event)
    # Process event
  end
end
