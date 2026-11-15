# frozen_string_literal: true

module TeachMeHipaa
  module Core
    # Reads what a Delivery's caller passed to Webhook.construct_event.
    #
    # @api private
    module WebhookInput
      # Time.iso8601 also takes a date-time without an offset, read as local
      # time, which would silently shift the tolerance window.
      ISO_8601_DATE_TIME = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})\z/

      module_function

      # Matches +name+ in any case, and as a Rack env key (HTTP_X_TMH_...),
      # so a Hash, a Rack env and Rails' request.headers all work.
      def header(headers, name)
        rack_name = "HTTP_#{name.upcase.tr("-", "_")}"
        headers.each do |key, value|
          key = key.to_s
          return value if key == rack_name || key.downcase == name
        end
        nil
      end

      def required_header(headers, name)
        value = header(headers, name)
        return value if value.is_a?(String) && !value.empty?

        raise WebhookSignatureError.new(
          "missing_header",
          "No #{name} header found on the Delivery. Are you passing the request headers as TeachMeHIPAA " \
          "sent them?",
        )
      end

      # Mirrors the platform signer, which signs the endpoint URL's path and
      # query and takes a "/"-prefixed path as given.
      def path_and_query(path)
        return path if path.to_s.start_with?("/")

        uri = URI.parse(path.to_s)
        raise URI::InvalidURIError unless uri.is_a?(URI::HTTP) && uri.host

        query = uri.query.to_s.empty? ? "" : "?#{uri.query}"
        "#{uri.path.empty? ? "/" : uri.path}#{query}"
      rescue URI::InvalidURIError
        raise ArgumentError, "path must be the request path (such as \"/webhooks/tmh?x=1\") or the full " \
                             "request URL, got #{path.inspect}"
      end

      def check_secret(secret)
        return if secret.is_a?(String) && !secret.empty?

        raise ArgumentError, "secret must be the Webhook subscription's Signing secret; got #{secret.inspect}"
      end

      def parse_timestamp(timestamp)
        raise ArgumentError unless ISO_8601_DATE_TIME.match?(timestamp)

        Time.iso8601(timestamp)
      rescue ArgumentError
        raise WebhookSignatureError.new(
          "invalid_timestamp", "The x-tmh-timestamp header #{timestamp.inspect} is not an ISO 8601 date-time."
        )
      end

      # A Test delivery is not an Event envelope (ADR-0005), so it never
      # reaches the Event union, whose fallback would misread it.
      def parse(payload)
        data = JSON.parse(payload.dup.force_encoding(Encoding::UTF_8))
        return TestDelivery.new(data) if data["test"] == true && data.key?("subscriptionId")

        Event.new(data)
      end
    end
  end

  # Verifies Deliveries and signs payloads for your own tests (ADR-0005).
  # Needs only the Signing secret, never API credentials. Also reachable as
  # +client.webhooks+.
  #
  # In Rails, pass the raw body and +request.headers+:
  #
  #   event = TeachMeHipaa::Webhook.construct_event(
  #     request.raw_post, request.headers, ENV.fetch("TMH_SIGNING_SECRET"), request.fullpath,
  #   )
  #
  # In Rack or Sinatra, pass the env, whose keys look like
  # +HTTP_X_TMH_SIGNATURE+:
  #
  #   event = TeachMeHipaa::Webhook.construct_event(
  #     request.body.read, request.env, secret, request.fullpath,
  #   )
  #
  # Any Hash of headers works too, with names in any case
  # (<tt>"X-TMH-Signature"</tt> or <tt>"x-tmh-signature"</tt>).
  module Webhook
    # Seconds a Delivery's timestamp may be from now, in either direction.
    DEFAULT_TOLERANCE = 300

    HEX_SHA256 = /\A[0-9a-f]{64}\z/
    RAW_BODY_HINT = "Are you passing the raw request body exactly as received? Parsed and re-serialized " \
                    "JSON does not verify."
    Input = Core::WebhookInput
    private_constant :HEX_SHA256, :RAW_BODY_HINT, :Input

    class << self
      # Verifies a Delivery and returns its Event, or a TeachMeHipaa::TestDelivery
      # for a test ping.
      #
      # +payload+ is the raw request body exactly as received. +path+ is the
      # path, with its query string, the request arrived on (or the full
      # request URL): the signature covers both. +headers+ is a Hash in any
      # key case, a Rack env, or anything whose +each+ yields name and value.
      # An Event type this version doesn't know comes back as a
      # TeachMeHipaa::UnknownEvent. +received_at+ (a Time) defaults to now.
      #
      # Raises TeachMeHipaa::WebhookSignatureError when the Delivery fails
      # verification, and ArgumentError for a nil or empty secret, a malformed
      # +path+ or a +tolerance+ that isn't a positive number of seconds.
      def construct_event(payload, headers, secret, path, tolerance: DEFAULT_TOLERANCE, received_at: nil)
        signed_path = Input.path_and_query(path)
        Input.check_secret(secret)
        unless tolerance.is_a?(Numeric) && tolerance.positive?
          raise ArgumentError, "tolerance must be a positive number of seconds"
        end

        signature = Input.required_header(headers, "x-tmh-signature")
        timestamp = Input.required_header(headers, "x-tmh-timestamp")
        signed_at = Input.parse_timestamp(timestamp)
        body_hash = OpenSSL::Digest::SHA256.hexdigest(payload)
        check_body_hash(Input.header(headers, "x-tmh-body-hash"), body_hash)
        verify_signature(signature, sign(secret, signed_path, timestamp, body_hash))
        check_tolerance(signed_at, received_at || Time.now, tolerance, timestamp)

        Input.parse(payload)
      end

      # Returns the headers TeachMeHIPAA would send with +payload+ to +path+,
      # so you can test your handler without a real Delivery. +payload+ must
      # be the exact body you will send; +timestamp+ (a Time) defaults to now.
      def generate_test_headers(payload:, secret:, path:, timestamp: nil, event_type: nil, event_id: nil,
                                key_id: nil)
        Input.check_secret(secret)
        # The platform's format: JavaScript's Date#toISOString, always UTC
        # with milliseconds.
        formatted = (timestamp || Time.now).getutc.strftime("%Y-%m-%dT%H:%M:%S.%LZ")
        body_hash = OpenSSL::Digest::SHA256.hexdigest(payload)
        {
          "x-tmh-key-id" => key_id,
          "x-tmh-timestamp" => formatted,
          "x-tmh-signature" => sign(secret, Input.path_and_query(path), formatted, body_hash),
          "x-tmh-body-hash" => body_hash,
          "x-tmh-event-type" => event_type,
          "x-tmh-event-id" => event_id,
          "content-type" => "application/json",
        }.compact
      end

      private

      def check_body_hash(sent, body_hash)
        return if sent.nil? || sent == body_hash

        raise WebhookSignatureError.new(
          "body_hash_mismatch", "The x-tmh-body-hash header does not match the body. #{RAW_BODY_HINT}"
        )
      end

      def verify_signature(signature, expected)
        # The format check comes first: fixed_length_secure_compare refuses
        # strings of different byte lengths.
        return if HEX_SHA256.match?(signature) && OpenSSL.fixed_length_secure_compare(expected, signature)

        raise WebhookSignatureError.new(
          "signature_mismatch",
          "No signature matched the expected signature for this Delivery. #{RAW_BODY_HINT} Are you " \
          "passing the exact request path, with its query string, that the Delivery was sent to, and " \
          "the Webhook subscription's Signing secret?",
        )
      end

      # Unlike Stripe, future timestamps are refused too (ADR-0005).
      def check_tolerance(signed_at, received_at, tolerance, timestamp)
        return if (received_at - signed_at).abs <= tolerance

        raise WebhookSignatureError.new(
          "timestamp_outside_tolerance",
          "The Delivery's timestamp #{timestamp} is more than #{tolerance} seconds from now. Check your " \
          "server's clock; otherwise the Delivery is being replayed.",
        )
      end

      # ADR-0005: the key is the Signing secret's UTF-8 bytes. The secret
      # looks like base64, but the platform never decodes it.
      def sign(secret, path, timestamp, body_hash)
        OpenSSL::HMAC.hexdigest("SHA256", secret, "POST\n#{path}\n#{timestamp}\n#{body_hash}")
      end
    end
  end
end
