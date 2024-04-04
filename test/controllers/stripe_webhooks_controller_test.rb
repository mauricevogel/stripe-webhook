require "test_helper"

class StripeWebhooksControllerTest < ActionDispatch::IntegrationTest
  def setup
    @stripe_http_signature = "test-signature"
    @sample_event = OpenStruct.new(
      id: "evt_1HHn3vFdCX2Ck6LQQG1J6EZ9",
      type: "customer.subscription.created",
      data: { object: { id: "sub_1HHn3vFdCX2Ck6LQQG1J6EZ9" } }
    )
  end

  test "with actionable event types, creates stripe even record" do
    webhook_params = { id: @sample_event.id, type: @sample_event.type, data: @sample_event.data }

    Stripe::Webhook
      .expects(:construct_event)
      .with(webhook_params.to_json, @http_signature, nil)
      .returns(@sample_event)

    assert_difference -> { StripeEvent.count }, 1 do
      post stripe_webhooks_path,
           headers: { "HTTP_STRIPE_SIGNATURE" => @http_signature },
           params: webhook_params,
           as: :json

      assert_response :success
    end
  end

  test "with non actionable event types, does not create stripe event record" do
    webhook_params = { id: @sample_event.id, type: "customer.subscription.updated", data: @sample_event.data }

    Stripe::Webhook
      .expects(:construct_event)
      .with(webhook_params.to_json, @http_signature, nil)
      .returns(OpenStruct.new(webhook_params))

    assert_no_difference -> { StripeEvent.count } do
      post stripe_webhooks_path,
           headers: { "HTTP_STRIPE_SIGNATURE" => @http_signature },
           params: webhook_params, as: :json

      assert_response :success
    end
  end

  test "with invalid signature, returns bad request" do
    webhook_params = { id: @sample_event.id, type: @sample_event.type, data: @sample_event.data }

    post stripe_webhooks_path,
         headers: { "HTTP_STRIPE_SIGNATURE" => "invalid" },
         params: webhook_params,
         as: :json

    assert_response :bad_request
  end

  test "with invalid payload, returns bad request" do
    Stripe::Webhook::Signature.expects(:verify_header).returns(true)

    post stripe_webhooks_path,
         headers: { "HTTP_STRIPE_SIGNATURE" => @http_signature },
         params: nil

    assert_response :bad_request
  end
end
