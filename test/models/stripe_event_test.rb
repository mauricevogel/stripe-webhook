require "test_helper"

class StripeEventTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @event = stripe_events(:subscription_created_event)
  end

  test "stripe_id is used as the primary key" do
    assert_equal "stripe_id", StripeEvent.primary_key
    assert_equal @event.stripe_id, @event.id
  end

  test "validates event_type is included in ACTIONABLE_EVENT_TYPES" do
    @event.event_type = "invalid"

    assert_not @event.valid?
    assert_includes @event.errors[:event_type], "is not included in the list"
  end

  test "stripe event record is readonly after creation" do
    assert @event.readonly?
  end

  test "after creation, enqueues a job to process the event" do
    event = StripeEvent.new(
      stripe_id: "evt_123",
      event_type: "customer.subscription.created",
      data: { object: { id: "evt_123" } }
    )

    assert_enqueued_with(job: ProcessStripeEventsJob, args: [event]) do
      event.save!
    end
  end
end
