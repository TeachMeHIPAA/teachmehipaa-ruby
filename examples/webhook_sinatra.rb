# frozen_string_literal: true

# A Sinatra endpoint for Webhook subscription Deliveries. It verifies each
# Delivery with the raw body, the headers and the exact request path, then
# dispatches on the Event's type.
#
#   TMH_WEBHOOK_SECRET=... bundle exec ruby -Ilib examples/webhook_sinatra.rb
#
# Then create a Webhook subscription whose endpoint_url reaches
# http://localhost:4567/webhooks/tmh (through a tunnel, say), and send it a
# Test delivery with client.webhook_subscriptions.test.

require "sinatra/base"
require "teachmehipaa"

# Receives TeachMeHIPAA Deliveries on POST /webhooks/tmh.
class TmhWebhookApp < Sinatra::Base
  post "/webhooks/tmh" do
    event = TeachMeHipaa::Webhook.construct_event(
      request.body.read,
      request.env,
      ENV.fetch("TMH_WEBHOOK_SECRET"),
      request.fullpath,
    )
    handle(event)
    status 204
  rescue TeachMeHipaa::WebhookSignatureError => e
    logger.warn("rejected a Delivery: #{e.code}")
    halt 400, e.code
  end

  helpers do
    # Answer quickly: hand slow work to a background job in a real app.
    def handle(event)
      case event
      when TeachMeHipaa::TestDelivery
        logger.info("Test delivery for #{event.subscription_id}")
      when TeachMeHipaa::EventLearnerCertified
        logger.info("#{event.data.email} is certified")
      when TeachMeHipaa::EventLearnerExpiring
        logger.info("#{event.data.email} needs to renew")
      else
        # Event types this version doesn't know arrive as UnknownEvent.
        logger.info("ignored #{event.event_type} #{event.event_id}")
      end
    end
  end

  run! if app_file == $PROGRAM_NAME
end
