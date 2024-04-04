class ProcessStripeEventsJob < ApplicationJob
  queue_as :default

  def perform(stripe_event)
    case stripe_event.event_type
    when "customer.subscription.created"
      process_subscription_created(stripe_event)
    end
  end

  private

  def process_subscription_created(stripe_event)
    stripe_subscription = stripe_event.data["object"]
    Subscription.create!(stripe_id: stripe_subscription["id"], stripe_customer_id: stripe_subscription["customer"])
  end
end
