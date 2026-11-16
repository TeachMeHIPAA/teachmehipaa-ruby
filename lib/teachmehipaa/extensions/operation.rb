# frozen_string_literal: true

module TeachMeHipaa
  # The file an export Operation produced (+enrollments.export+,
  # +certificates.export+ or +learners.export+), from Operation#export_result.
  # +csv+ is the whole file as UTF-8 text (RFC 4180, CRLF line endings),
  # +filename+ a suggested name such as "enrollments-org_acme.csv", and
  # +row_count+ the number of data rows, not counting the header. Either of
  # the last two is nil when the API leaves it out.
  ExportResult = Data.define(:csv, :filename, :row_count) do
    # The CSV stays out of inspect output: it holds Learners' names and
    # emails.
    def inspect
      "#<#{self.class.name} filename=#{filename.inspect} row_count=#{row_count.inspect} bytes=#{csv.bytesize}>"
    end
  end

  # Work that may finish after the request that started it, such as an
  # export or a redrive (grilling Q24). +response+ holds the result once
  # +done+ is true, unless +error+ holds the problem.
  #
  # Most Operations are done when they are returned; Test deliveries and
  # redrives finish later, so call #wait:
  #
  #   operation = client.webhook_subscriptions.test(subscription_id).wait
  class Operation < OperationBase
    # The default +timeout:+ of #wait, in seconds.
    DEFAULT_WAIT_TIMEOUT = 300.0
    # The default +interval:+ of #wait, in seconds.
    DEFAULT_WAIT_INTERVAL = 1.0
    # The longest #wait backs off to between polls, in seconds.
    MAX_WAIT_INTERVAL = 10.0
    # An Operation's +name+; the capture is its operation id.
    NAME_PATTERN = %r{\Aorganizations/[^/\s]+/operations/([^/\s]+)\z}

    # The operation id in an Operation's +name+, which is
    # <tt>organizations/{orgId}/operations/{operationId}</tt>: what
    # +operations.retrieve+ takes. Raises ArgumentError for anything else.
    def self.operation_id_from_name(name)
      match = NAME_PATTERN.match(name)
      return match[1] if match

      raise ArgumentError, "#{name.inspect} is not an Operation name (organizations/{orgId}/operations/{operationId})"
    end

    # Seconds to wait before poll +poll_number+ (from 1). The ceiling
    # doubles from +interval+ up to 10 s, and jitter picks 50-100% of it so
    # that many waiters don't poll in step. Nothing waits less than
    # +interval+, and an +interval+ longer than the cap stays as it is.
    #
    # @api private
    def self.poll_delay(interval, poll_number)
      Core::Retries.backoff(interval, poll_number - 1, [MAX_WAIT_INTERVAL, interval].max)
    end

    # @api private
    def initialize(data, last_response: nil, requestor: nil)
      # Kept out of #to_h and equality: two reads of one Operation are equal
      # whichever client polled them.
      @requestor = requestor
      super(data, last_response:)
    end

    # Polls until the Operation is done and returns its final state. An
    # Operation that is already done returns itself, without a request.
    #
    # The first poll comes +interval+ seconds after the call; later ones back
    # off to 10 s apart. The last poll lands on the +timeout+, in seconds.
    # The client's +sleep:+ and +clock:+ do the waiting and timekeeping.
    #
    # Raises OperationFailedError, with the problem's fields, when the
    # Operation finished with an error, and OperationTimeoutError, carrying
    # the last state seen, when it is not done within +timeout+.
    def wait(timeout: DEFAULT_WAIT_TIMEOUT, interval: DEFAULT_WAIT_INTERVAL)
      return settled if done

      timeout, interval = check_wait(timeout, interval)
      deadline = clock.call + timeout
      latest = self
      (1..).each do |poll_number|
        remaining = deadline - clock.call
        raise timed_out(latest, timeout) unless remaining.positive?

        delay = Operation.poll_delay(interval, poll_number)
        latest = poll_after([delay, remaining].min)
        return latest.settled if latest.done
        # That poll was the one at the deadline.
        raise timed_out(latest, timeout) if delay >= remaining
      end
    end

    # The CSV file of a done export Operation, as an ExportResult.
    #
    # Raises OperationFailedError if the export failed, and ArgumentError
    # (calling it is the mistake, as with any misuse of the library) for an
    # Operation that is not done or is not a CSV export.
    def export_result
      raise ArgumentError, "Operation #{name} is not done; call wait first" unless done

      # The spec says only that an export's response "holds the CSV file". The
      # API sends it inline as the monorepo's ExportArtifact:
      # {format: "csv", contentType, filename, rowCount, dataBase64}.
      settled
      # Read raw: a subclass may type +response+ as something else.
      artifact = @data["response"]
      unless artifact.is_a?(Hash) && artifact["format"] == "csv" && artifact["dataBase64"].is_a?(String)
        raise ArgumentError, "Operation #{name} did not produce a CSV export"
      end

      filename, row_count = artifact.values_at("filename", "rowCount")
      ExportResult.new(csv: decode_csv(artifact["dataBase64"]), filename: (filename if filename.is_a?(String)),
                       row_count: (row_count if row_count.is_a?(Integer)))
    end

    protected

    # This finished Operation, or the error it finished with.
    def settled
      raise OperationFailedError.from_operation(self) unless error.nil?

      self
    end

    # This Operation read into +model+, an Operation subclass.
    def read_as(model)
      model.new(@data, last_response:, requestor: @requestor)
    end

    private

    def check_wait(timeout, interval)
      raise ArgumentError, "timeout must be zero or more seconds" unless timeout.is_a?(Numeric) && !timeout.negative?
      return [timeout, interval.to_f] if interval.is_a?(Numeric) && interval.positive?

      raise ArgumentError, "interval must be a positive number of seconds"
    end

    def requestor
      return @requestor if @requestor

      raise ArgumentError, "Operation #{name} was not returned by an API call, so it has no client to poll with"
    end

    def clock
      requestor.config.clock
    end

    # Polls with the generated operations.retrieve, then reads the result
    # into this Operation's own class, so a typed +response+ stays typed.
    def poll_after(seconds)
      requestor.config.sleep.call(seconds)
      polled = Resources::Operations.new(requestor).retrieve(operation_id)
      polled.instance_of?(self.class) ? polled : polled.read_as(self.class)
    end

    def operation_id
      Operation.operation_id_from_name(name)
    end

    # Strict base64 (unpack's "m0") without the base64 gem, which is no
    # longer a default gem (ADR-0008: zero dependencies).
    def decode_csv(data_base64)
      data_base64.unpack1("m0").force_encoding(Encoding::UTF_8)
    rescue ArgumentError
      raise ArgumentError, "Operation #{name} did not produce a CSV export"
    end

    def timed_out(operation, timeout)
      OperationTimeoutError.new("Operation #{name} was not done after #{format("%g", timeout)} s", operation:)
    end
  end

  # How a Test delivery or a redrive ended: the +response+ of the
  # WebhookDeliveryOperation that +webhook_subscriptions.test+ and +.redrive+
  # return. The spec leaves it untyped; the webhook worker settles it with
  # one of these. Tell the variants apart by +tag+ or by class. Others may
  # appear, read as WebhookDeliveryResult::Unknown, so handle tags you don't
  # recognize.
  module WebhookDeliveryResult
    extend Union

    # A WebhookDeliveryResult this library doesn't know yet. Its fields are
    # all kept; read them with #[] or #to_h.
    class Unknown < Model
      include WebhookDeliveryResult

      # The result's kind, a value this library doesn't know yet.
      field :tag, "_tag"
    end

    variants(
      {
        "failed" => "WebhookDeliveryFailed",
        "sent" => "WebhookDeliverySent",
        "settled" => "WebhookDeliverySettled",
      },
      property: "_tag",
      fallback: "WebhookDeliveryResult::Unknown",
    )
  end

  # The endpoint accepted the Delivery.
  class WebhookDeliverySent < Model
    include WebhookDeliveryResult

    # "sent".
    field :tag, "_tag"
    # The endpoint's HTTP status.
    field :response_status, "responseStatus"
  end

  # Delivery stopped for good; +reason+ says why.
  class WebhookDeliveryFailed < Model
    include WebhookDeliveryResult

    # "failed".
    field :tag, "_tag"
    # Why delivery stopped, such as "endpoint_gone".
    field :reason, "reason"
    # The endpoint's last HTTP status, or nil when it never answered.
    field :response_status, "responseStatus"
  end

  # The Delivery had already ended before this Operation; +status+ says how.
  class WebhookDeliverySettled < Model
    include WebhookDeliveryResult

    # "settled".
    field :tag, "_tag"
    # How the Delivery ended, such as "delivered".
    field :status, "status"
  end

  # An Operation from +webhook_subscriptions.test+ or +.redrive+, whose
  # +response+ is a WebhookDeliveryResult once it is done.
  class WebhookDeliveryOperation < Operation
    # How the Delivery ended, once +done+ is true.
    field :response, "response", type: WebhookDeliveryResult
  end
end
