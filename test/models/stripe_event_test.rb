require "test_helper"

class StripeEventTest < ActiveSupport::TestCase
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
end
