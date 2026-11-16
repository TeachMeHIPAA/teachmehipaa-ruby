# frozen_string_literal: true

require_relative "test_helper"

# Certificate PDF downloads, whole and streamed to a block, through the
# public client.
class CertificatePdfTest < Minitest::Test
  include ClientHelpers

  CERTIFICATE_ID = "cert_01JD8F"
  PATH = "/organizations/#{Fixtures::ORG_ID}/certificates/#{CERTIFICATE_ID}/content".freeze
  ACCEPT = "application/pdf, application/problem+json"
  # Every byte value, so any text decoding along the way would show.
  EVERY_BYTE = (0..255).to_a.pack("C*").freeze
  DISPOSITION = { "content-disposition" => 'attachment; filename="certificate-ana.pdf"' }.freeze
  PDF = FakeTransport::Reply.new(status: 200, body: EVERY_BYTE, content_type: "application/pdf", headers: DISPOSITION)
  HTML_PAGE = FakeTransport::Reply.new(status: 200, body: "<!doctype html><title>Not found</title>",
                                       content_type: "text/html", headers: {})

  def setup
    @transport = FakeTransport.new(chunk_size: 100)
    @transport.on("POST", "/auth/token", FakeTransport::Reply.json(token_json))
    @client = build_client(@transport, organization_id: ORG_ID, sleep: FakeSleep.new)
  end

  def test_every_byte_comes_back_unchanged_with_type_and_filename
    @transport.on("GET", PATH, PDF)

    pdf = @client.certificates.download_pdf(CERTIFICATE_ID)

    assert_instance_of TeachMeHipaa::BinaryResponse, pdf
    assert_equal EVERY_BYTE, pdf.data
    assert_equal Encoding::BINARY, pdf.data.encoding
    assert_equal ["application/pdf", "certificate-ana.pdf", 200],
                 [pdf.content_type, pdf.filename, pdf.last_response.status]
    assert_equal ACCEPT, only(@transport.requests_to("GET", PATH)).headers["accept"]
  end

  def test_a_utf8_filename_is_preferred_over_the_plain_one
    disposition = %(attachment; filename="certificate-jose.pdf"; filename*=UTF-8''certificate-jos%C3%A9.pdf)
    @transport.on("GET", PATH, FakeTransport::Reply.new(status: 200, body: EVERY_BYTE, content_type: "application/pdf",
                                                        headers: { "content-disposition" => disposition }))

    assert_equal "certificate-josé.pdf", @client.certificates.download_pdf(CERTIFICATE_ID).filename
  end

  def test_a_problem_response_raises_the_typed_error
    @transport.on("GET", PATH, problem(404, "not_found", title: "Not found", detail: "No such certificate."))

    error = assert_raises(TeachMeHipaa::NotFoundError) { @client.certificates.download_pdf(CERTIFICATE_ID) }

    assert_equal ["not_found", REQUEST_ID], [error.code, error.request_id]
  end

  def test_an_html_page_is_not_handed_back_as_a_pdf
    @transport.on("GET", PATH, HTML_PAGE)

    assert_raises(TeachMeHipaa::APIError) { @client.certificates.download_pdf(CERTIFICATE_ID) }
  end

  def test_a_block_receives_every_byte_unchanged_in_chunks
    @transport.on("GET", PATH, PDF)
    chunks = []

    pdf = @client.certificates.download_pdf(CERTIFICATE_ID) { |chunk| chunks << chunk }

    assert_operator chunks.length, :>, 1
    assert_equal EVERY_BYTE, chunks.join
    assert(chunks.all? { |chunk| chunk.encoding == Encoding::BINARY })
    assert_instance_of TeachMeHipaa::StreamedResponse, pdf
    assert_equal ["application/pdf", "certificate-ana.pdf", 200],
                 [pdf.content_type, pdf.filename, pdf.last_response.status]
    assert_equal ACCEPT, only(@transport.requests_to("GET", PATH)).headers["accept"]
  end

  def test_a_streamed_download_is_retried_until_the_file_starts
    @transport.on("GET", PATH, problem(503, "temporarily_unavailable"))
    @transport.on("GET", PATH, PDF)
    received = +"".b

    @client.certificates.download_pdf(CERTIFICATE_ID) { |chunk| received << chunk }

    assert_equal EVERY_BYTE, received
    assert_equal 2, @transport.requests_to("GET", PATH).length
  end

  def test_a_streamed_problem_response_raises_the_typed_error_without_calling_the_block
    @transport.on("GET", PATH, problem(404, "not_found", title: "Not found"))
    chunks = []

    assert_raises(TeachMeHipaa::NotFoundError) do
      @client.certificates.download_pdf(CERTIFICATE_ID) { |chunk| chunks << chunk }
    end
    assert_empty chunks
  end

  def test_a_streamed_html_page_raises_without_calling_the_block
    @transport.on("GET", PATH, HTML_PAGE)
    chunks = []

    assert_raises(TeachMeHipaa::APIError) do
      @client.certificates.download_pdf(CERTIFICATE_ID) { |chunk| chunks << chunk }
    end
    assert_empty chunks
  end

  def test_an_error_raised_by_the_block_reaches_the_caller_unchanged_and_is_not_retried
    @transport.on("GET", PATH, PDF)

    assert_raises(Errno::ENOSPC) do
      @client.certificates.download_pdf(CERTIFICATE_ID) { |_chunk| raise Errno::ENOSPC }
    end
    assert_equal 1, @transport.requests_to("GET", PATH).length
  end

  def test_a_connection_lost_mid_file_is_not_retried
    dropped = FakeTransport::Reply.new(status: 200, body: FakeTransport::Dropped.new(EVERY_BYTE[0, 100]),
                                       content_type: "application/pdf", headers: DISPOSITION)
    @transport.on("GET", PATH, dropped)
    @transport.on("GET", PATH, PDF)
    received = +"".b

    assert_raises(TeachMeHipaa::APIConnectionError) do
      @client.certificates.download_pdf(CERTIFICATE_ID) { |chunk| received << chunk }
    end
    # A replay would write the first bytes into the caller's file twice.
    assert_equal EVERY_BYTE[0, 100], received
    assert_equal 1, @transport.requests_to("GET", PATH).length
  end
end
