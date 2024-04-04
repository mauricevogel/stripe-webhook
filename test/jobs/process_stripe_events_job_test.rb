require "test_helper"

class ProcessStripeEventsJobTest < ActiveJob::TestCase
  test "when enqueued with a customer.subscription.created event, it creates a subscription record" do
    stripe_event = stripe_events(:subscription_created_event)

    assert_difference -> { Subscription.count }, 1 do
      ProcessStripeEventsJob.perform_now(stripe_event)
    end

    assert_not_nil Subscription.find_by(stripe_id: stripe_event.data["object"]["id"])
  end

  test "when enqueued with an invoice.paid event, it marks the subscription as paid" do
    stripe_event = stripe_events(:invoice_paid_event)
    subscription = Subscription.create!(
      stripe_id: stripe_event.data["object"]["subscription"],
      stripe_customer_id: "cus_1"
    )

    assert_changes -> { subscription.reload.state }, from: "unpaid", to: "paid" do
      ProcessStripeEventsJob.perform_now(stripe_event)
    end
  end

  test "when enqueued with an invoice.paid event and the subscription is not found, it re-enqueues the job" do
    stripe_event = stripe_events(:invoice_paid_event)

    assert_enqueued_with(job: ProcessStripeEventsJob, args: [stripe_event]) do
      ProcessStripeEventsJob.perform_now(stripe_event)
    end
  end
end
