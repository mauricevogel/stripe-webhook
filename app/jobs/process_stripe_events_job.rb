class ProcessStripeEventsJob < ApplicationJob
  queue_as :default

  def perform(stripe_event)
    case stripe_event.event_type
    when "customer.subscription.created"
      process_subscription_created(stripe_event)
    when "customer.subscription.deleted"
      process_subscription_deleted(stripe_event)
    when "invoice.paid"
      process_invoice_paid(stripe_event)
    end
  end

  private

  def process_invoice_paid(stripe_event)
    stripe_invoice = stripe_event.data["object"]
    subscription = Subscription.find_by(stripe_id: stripe_invoice["subscription"])

    # This will re-enqueue the job with a tiny offset if the subscription is not found yet.
    # As Stripe can not guarantee the order of events coming in, we need to be prepared for a scenario
    # where the invoice.paid event arrives before the customer.subscription.created event.
    #
    # Usually I would suggest a more thorough solution (e.g. fetching the subscription directly OR at least
    # having an upper retry limit), but for the scope of the coding challenge here, I will keep it simple.
    self.class.set(wait: 2.seconds).perform_later(stripe_event) and return if subscription.blank?

    subscription.pay!
  end

  def process_subscription_created(stripe_event)
    stripe_subscription = stripe_event.data["object"]
    Subscription.create!(stripe_id: stripe_subscription["id"], stripe_customer_id: stripe_subscription["customer"])
  end

  def process_subscription_deleted(stripe_event)
    stripe_subscription = stripe_event.data["object"]
    subscription = Subscription.find_by(stripe_id: stripe_subscription["id"])

    # As per the acceptance criteria of the challenge, we won't cancel unpaid subscriptions. The model would prevent
    # that as well.
    #
    # In a real case scenario the cancelation would most likely not be triggered via Stripe directly,
    # but via a user action in the application. In that case, we could correctly handle the cancelation process.
    subscription.cancel! if subscription&.paid?
  end
end
