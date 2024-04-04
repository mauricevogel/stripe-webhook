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

  test "when enqueued with an invoice.paid event and the subscription is already paid,
        it does not change the subscription" do
    stripe_event = stripe_events(:invoice_paid_event)
    subscription = Subscription.create!(
      stripe_id: stripe_event.data["object"]["subscription"],
      stripe_customer_id: "cus_1",
      state: "paid",
      paid_at: Time.zone.now
    )

    assert_no_changes -> { subscription.reload } do
      ProcessStripeEventsJob.perform_now(stripe_event)
    end
  end

  test "when enqueued with an invoice.paid event and the subscription is not found, it re-enqueues the job" do
    stripe_event = stripe_events(:invoice_paid_event)

    assert_enqueued_with(job: ProcessStripeEventsJob, args: [stripe_event]) do
      ProcessStripeEventsJob.perform_now(stripe_event)
    end
  end

  test "when enqueued with a customer.subscription.deleted event, it cancels the subscription if it is paid" do
    stripe_event = stripe_events(:subscription_deleted_event)
    subscription = Subscription.create!(
      stripe_id: stripe_event.data["object"]["id"],
      stripe_customer_id: stripe_event.data["object"]["customer"],
      state: "paid",
      paid_at: Time.zone.now
    )

    assert_changes -> { subscription.reload.state }, from: "paid", to: "canceled" do
      ProcessStripeEventsJob.perform_now(stripe_event)
    end
  end

  test "when enqueued with a customer.subscription.deleted event,
        it does not cancel the subscription if it is not paid" do
    stripe_event = stripe_events(:subscription_deleted_event)
    subscription = Subscription.create!(
      stripe_id: stripe_event.data["object"]["id"],
      stripe_customer_id: stripe_event.data["object"]["customer"]
    )

    assert_no_changes -> { subscription.reload.state } do
      ProcessStripeEventsJob.perform_now(stripe_event)
    end
  end
end
