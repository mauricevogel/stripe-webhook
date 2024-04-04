class StripeWebhooksController < ApplicationController
  protect_from_forgery except: :create

  def create
    event = Stripe::Webhook.construct_event(
      request.body.read,
      request.env["HTTP_STRIPE_SIGNATURE"],
      Rails.application.credentials.dig(:stripe, :webhook_secret)
    )

    # We want to return early if the event is not actionable or has already been stored, which
    # can happen occasionally as per Stripes documentation
    head :ok and return unless StripeEvent::ACTIONABLE_EVENT_TYPES.include?(event.type)
    head :ok and return if StripeEvent.exists?(event.id)

    StripeEvent.create!(
      stripe_id: event.id,
      event_type: event.type,
      data: event.data
    )

    head :ok
  rescue JSON::ParserError, Stripe::SignatureVerificationError
    # Handle invalid payloads and signatures
    head :bad_request and return
  end
end
