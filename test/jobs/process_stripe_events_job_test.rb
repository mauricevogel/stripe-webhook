require "test_helper"

class ProcessStripeEventsJobTest < ActiveJob::TestCase
  test "when enqueued with a customer.subscription.created event, it creates a subscription record" do
    stripe_event = stripe_events(:subscription_created_event)

    assert_difference -> { Subscription.count }, 1 do
      ProcessStripeEventsJob.perform_now(stripe_event)
    end

    assert_not_nil Subscription.find_by(stripe_id: stripe_event.data["object"]["id"])
  end
end
