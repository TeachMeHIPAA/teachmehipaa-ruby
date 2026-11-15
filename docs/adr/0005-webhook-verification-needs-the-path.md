# Webhook verification takes the request path, and Test deliveries are their own type

The Delivery signature covers `POST\n<path+query>\n<timestamp>\n<sha256(body)>`
and uses the Signing secret's UTF-8 bytes (not base64-decoded) as the HMAC
key. That is unlike Stripe, which signs `t.payload`, so `constructEvent` takes
the path the request arrived on as well as the raw body, headers and secret.
It rejects timestamps more than 5 minutes off in either direction (Stripe only
rejects old ones). A Test delivery is not an Event envelope (`{subscriptionId,
test: true}` with a UUID id), so verification returns `Event | TestDelivery`
instead of failing strict parsing on test pings.
