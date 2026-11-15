# frozen_string_literal: true

require_relative "test_helper"
require "pathname"
require "stringio"
require "tmpdir"

# Enrollment CSV imports as multipart bodies, through the public client.
class EnrollmentImportTest < Minitest::Test
  include ClientHelpers

  PATH = "/organizations/#{Fixtures::ORG_ID}/enrollments:import".freeze
  UUID_V4 = /\A\h{8}-\h{4}-4\h{3}-[89ab]\h{3}-\h{12}\z/
  # RFC 4180 with CRLF, a quoted comma and non-ASCII UTF-8.
  CSV_TEXT = %(email,name\r\nana@example.com,"Lima, Ana"\r\njose@example.com,José Núñez\r\n)
  CSV = CSV_TEXT.b.freeze
  EVERY_BYTE = (0..255).to_a.pack("C*").freeze

  # dev#/components/schemas/ImportPreview
  PREVIEW_JSON = {
    "totalRows" => 2, "validRows" => 2, "seatsRequired" => 2, "seatsAvailable" => 10,
    "rows" => [
      { "rowNumber" => 2, "email" => "ana@example.com", "courseId" => "hipaa-2026", "status" => "valid" },
      { "rowNumber" => 3, "email" => "jose@example.com", "courseId" => "hipaa-2026", "status" => "valid" },
    ]
  }.freeze
  # dev#/components/schemas/Operation, as a commit returns it (202).
  OPERATION_JSON = { "name" => "op_01JD8H", "kind" => "enrollments.import", "done" => false }.freeze
  ACCEPTED = FakeTransport::Reply.json(OPERATION_JSON, status: 202)

  def setup
    @transport = FakeTransport.new
    @transport.on("POST", "/auth/token", FakeTransport::Reply.json(token_json))
    @client = build_client(@transport, organization_id: ORG_ID, sleep: FakeSleep.new)
  end

  def test_a_preview_sends_a_csv_part_and_a_json_options_part
    @transport.on("POST", PATH, FakeTransport::Reply.json(PREVIEW_JSON))

    preview = @client.enrollments.preview_import(file: TeachMeHipaa::FilePart.new(CSV),
                                                 options: { course_id: "hipaa-2026" })

    assert_instance_of TeachMeHipaa::ImportPreview, preview
    assert_equal [2, %w[ana@example.com jose@example.com]], [preview.total_rows, preview.rows.map(&:email)]
    request = only(@transport.requests_to("POST", PATH))
    parts = parts_of(request)

    assert_equal %w[file options], parts.keys
    assert_equal ["text/csv", "file.csv", CSV], parts.fetch("file").values_at(:type, :filename, :content)
    assert_equal "application/json", parts.fetch("options")[:type]
    assert_equal({ "courseId" => "hipaa-2026", "validateOnly" => true }, JSON.parse(parts.fetch("options")[:content]))
    assert_match UUID_V4, request.headers["idempotency-key"]
  end

  def test_an_import_from_a_path_sends_the_file_unchanged_under_its_own_name
    with_roster do |roster|
      [roster, Pathname(roster)].each do |path|
        @transport.replace("POST", PATH, ACCEPTED)

        operation = @client.enrollments.import(file: path)

        assert_instance_of TeachMeHipaa::Operation, operation
        assert_equal ["op_01JD8H", false], [operation.name, operation.done]
      end
      @transport.requests_to("POST", PATH).each do |request|
        file = parts_of(request).fetch("file")

        assert_equal ["text/csv", "roster.csv", CSV], file.values_at(:type, :filename, :content)
        assert_equal({ "validateOnly" => false }, JSON.parse(parts_of(request).fetch("options")[:content]))
        assert_match UUID_V4, request.headers["idempotency-key"]
      end
    end
  end

  def test_an_open_file_is_sent_under_its_own_name
    @transport.on("POST", PATH, ACCEPTED)

    with_roster { |roster| File.open(roster, "rb") { |file| @client.enrollments.import(file:) } }

    file = parts_of(only(@transport.requests_to("POST", PATH))).fetch("file")

    assert_equal ["roster.csv", CSV], file.values_at(:filename, :content)
  end

  def test_an_in_memory_stream_is_sent_under_a_default_name
    @transport.on("POST", PATH, ACCEPTED)

    @client.enrollments.import(file: StringIO.new(CSV))

    file = parts_of(only(@transport.requests_to("POST", PATH))).fetch("file")

    assert_equal ["file.csv", CSV], file.values_at(:filename, :content)
  end

  def test_bytes_are_sent_under_the_filename_given
    @transport.on("POST", PATH, ACCEPTED)

    @client.enrollments.import(file: TeachMeHipaa::FilePart.new(CSV, filename: "march.csv"))

    file = parts_of(only(@transport.requests_to("POST", PATH))).fetch("file")

    assert_equal ["march.csv", CSV], file.values_at(:filename, :content)
  end

  def test_every_byte_value_is_uploaded_unchanged
    @transport.on("POST", PATH, ACCEPTED)

    @client.enrollments.import(file: TeachMeHipaa::FilePart.new(EVERY_BYTE))

    assert_equal EVERY_BYTE, parts_of(only(@transport.requests_to("POST", PATH))).fetch("file")[:content]
  end

  def test_a_retried_import_resends_identical_bytes_under_the_same_key
    @transport.on("POST", PATH, problem(503, "temporarily_unavailable"))
    @transport.on("POST", PATH, ACCEPTED)

    # A stream can be read only once, so this shows the file is read per call.
    @client.enrollments.import(file: StringIO.new(CSV))

    first, replay = @transport.requests_to("POST", PATH)

    assert_equal first.headers["idempotency-key"], replay.headers["idempotency-key"]
    assert_equal([CSV, CSV], [first, replay].map { |request| parts_of(request).fetch("file")[:content] })
  end

  def test_csv_text_passed_as_a_path_is_refused_before_sending
    error = assert_raises(ArgumentError) { @client.enrollments.preview_import(file: CSV_TEXT) }

    assert_match(/FilePart/, error.message)
    assert_empty @transport.requests
  end

  private

  def with_roster
    Dir.mktmpdir do |dir|
      path = File.join(dir, "roster.csv")
      File.binwrite(path, CSV)
      yield path
    end
  end

  # name => { type:, filename:, content: } for each part, in order, split
  # the way a server would.
  def parts_of(request)
    boundary = request.headers["content-type"][%r{\Amultipart/form-data; boundary=(\S+)\z}, 1]
    body = request.body.b

    assert body.end_with?("--#{boundary}--\r\n")

    body.split("--#{boundary}".b)[1...-1].to_h do |part|
      head, content = part.delete_prefix("\r\n").split("\r\n\r\n", 2)
      [head[/name="([^"]+)"/, 1], { type: head[/^Content-Type: (\S+)/, 1], filename: head[/filename="([^"]+)"/, 1],
                                    content: content.delete_suffix("\r\n") }]
    end
  end
end
