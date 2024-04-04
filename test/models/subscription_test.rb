require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase
  test "within unpaid state, can transition to paid" do
    subscription = subscriptions(:unpaid_subscription)

    assert subscription.can_pay?
    assert subscription.pay
    assert subscription.paid?
  end

  test "within paid state, can transition to canceled" do
    subscription = subscriptions(:paid_subscription)

    assert subscription.can_cancel?
    assert subscription.cancel
    assert subscription.canceled?
  end

  test "within unpaid state, can not transition to canceled" do
    subscription = subscriptions(:unpaid_subscription)

    assert_not subscription.can_cancel?
    assert_not subscription.cancel
  end

  test "when transitioning state, sets timestamp accordingly" do
    subscription = subscriptions(:unpaid_subscription)
    subscription.pay!

    assert_not_nil subscription.paid_at
  end
end
