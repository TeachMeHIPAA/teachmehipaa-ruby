# frozen_string_literal: true

require_relative "test_helper"
require "digest"
require_relative "../scripts/generator"

class GeneratedSurfaceTest < Minitest::Test
  include ClientHelpers

  ROOT = File.expand_path("..", __dir__)

  # The public method for every Developer API operation: research
  # api-sdk-surface.md §11 in snake_case, with the renames settled since
  # (grilling Q12: retrieve_links; the IR: auth.introspect and delete over
  # del) and the Q25 splits of importEnrollments and batchEnrollments.
  EXPECTED_METHODS = {
    "listAuditEvents" => ["audit_events.list"],
    "introspectAccessToken" => ["auth.introspect"],
    "getCertificateVerification" => ["certificate_verifications.retrieve"],
    "downloadCertificatePdf" => ["certificates.download_pdf"],
    "exportCertificates" => ["certificates.export"],
    "listCertificates" => ["certificates.list"],
    "getCertificate" => ["certificates.retrieve"],
    "getCertificateCredentials" => ["certificates.retrieve_links"],
    "getComplianceSummary" => ["compliance.retrieve"],
    "listCourses" => ["courses.list"],
    "getCourse" => ["courses.retrieve"],
    "batchEnrollments" => ["enrollments.batch", "enrollments.batch_by_filter"],
    "cancelEnrollment" => ["enrollments.cancel"],
    "createEnrollment" => ["enrollments.create"],
    "exportEnrollments" => ["enrollments.export"],
    "importEnrollments" => ["enrollments.import", "enrollments.preview_import"],
    "listEnrollments" => ["enrollments.list"],
    "remindEnrollment" => ["enrollments.remind"],
    "renewEnrollment" => ["enrollments.renew"],
    "resendEnrollmentInvite" => ["enrollments.resend_invite"],
    "getEnrollment" => ["enrollments.retrieve"],
    "listOrgEvents" => ["events.list"],
    "batchUpsertLearners" => ["learners.batch_upsert"],
    "createLearner" => ["learners.create"],
    "createLearnerLaunchLink" => ["learners.create_launch_link"],
    "exportLearners" => ["learners.export"],
    "listLearners" => ["learners.list"],
    "offboardLearner" => ["learners.offboard"],
    "remindLearner" => ["learners.remind"],
    "getLearner" => ["learners.retrieve"],
    "updateLearner" => ["learners.update"],
    "upsertLearnerByExternalId" => ["learners.upsert_by_external_id"],
    "listMembers" => ["members.list"],
    "getMember" => ["members.retrieve"],
    "getOperation" => ["operations.retrieve"],
    "createPartnerOrganization" => ["partners.organizations.create"],
    "listPartnerOrganizations" => ["partners.organizations.list"],
    "getPartner" => ["partners.retrieve"],
    "confirmPaymentMethod" => ["payment_method.confirm"],
    "removePaymentMethod" => ["payment_method.delete"],
    "preparePaymentMethod" => ["payment_method.prepare"],
    "getPaymentMethod" => ["payment_method.retrieve"],
    "setupPaymentMethod" => ["payment_method.setup"],
    "createSeatOrder" => ["seat_orders.create"],
    "listSeatOrders" => ["seat_orders.list"],
    "quoteSeatOrder" => ["seat_orders.quote"],
    "getSeatOrder" => ["seat_orders.retrieve"],
    "getSeatInventory" => ["seats.retrieve"],
    "createWebhookSubscription" => ["webhook_subscriptions.create"],
    "deleteWebhookSubscription" => ["webhook_subscriptions.delete"],
    "listWebhookSubscriptions" => ["webhook_subscriptions.list"],
    "redriveWebhookSubscription" => ["webhook_subscriptions.redrive"],
    "getWebhookSubscription" => ["webhook_subscriptions.retrieve"],
    "testWebhookSubscription" => ["webhook_subscriptions.test"],
    "updateWebhookSubscription" => ["webhook_subscriptions.update"],
  }.freeze

  # The token endpoint is implemented by the core's token providers.
  HAND_WRITTEN_OPERATIONS = ["createAccessToken"].freeze
  # Public methods with no operation of their own, from
  # lib/teachmehipaa/extensions: events.tail iterates listOrgEvents
  # (grilling Q22).
  HAND_WRITTEN_METHODS = ["events.tail"].freeze
  HTTP_METHODS = %w[get post put patch delete].freeze
  # The aliases rbs:test adds around each method it checks.
  RBS_ALIAS = /__with(out)?__/

  def test_reads_an_ir_built_from_the_vendored_spec
    spec = File.binread(File.join(ROOT, "openapi/openapi.developer.json"))

    assert_equal ir.dig("source", "sha256"), Digest::SHA256.hexdigest(spec)
    assert_equal ir.dig("source", "release"), File.read(File.join(ROOT, "OPENAPI_VERSION")).strip
  end

  def test_covers_every_developer_api_operation_except_the_token_endpoint
    covered = spec_operation_ids - HAND_WRITTEN_OPERATIONS

    assert_equal 55, covered.length
    assert_equal EXPECTED_METHODS.keys.sort, covered.sort
  end

  def test_exposes_exactly_one_public_method_per_ir_method_with_the_expected_name
    expected = EXPECTED_METHODS.values.flatten

    assert_equal 57, expected.length
    assert_equal (expected + HAND_WRITTEN_METHODS).sort, public_methods_of(build_client(FakeTransport.new)).keys.sort
  end

  def test_names_each_ir_method_as_its_operations_expected_public_method
    named = ir_methods.map { |name, method| [name, EXPECTED_METHODS.fetch(method["operationId"], [])] }

    named.each { |name, expected| assert_includes expected, name }
    assert_equal 57, named.map(&:first).uniq.length
  end

  def test_path_parameters_are_positional_and_no_method_takes_an_organization
    methods = public_methods_of(build_client(FakeTransport.new))

    ir_methods.each do |name, method|
      parameters = methods.fetch(name).parameters
      positional = parameters.filter_map { |kind, param| param.to_s if kind == :req }

      assert_equal method["pathParams"].map { |param| SdkGenerator::Naming.snake(param["name"]) }, positional, name
      refute(parameters.any? { |_, param| param.to_s.start_with?("org") }, name)
      assert_equal %i[key request_options], parameters.last, name
    end
  end

  def test_partner_methods_take_the_partner_id
    methods = public_methods_of(build_client(FakeTransport.new))

    %w[partners.retrieve partners.organizations.list partners.organizations.create].each do |name|
      assert_equal %i[req partner_id], methods.fetch(name).parameters.first, name
    end
  end

  def test_is_exactly_what_rake_generate_writes_from_the_vendored_ir
    files = SdkGenerator.generate(SdkGenerator.load_ir(ROOT))

    assert_equal files.keys.sort, SdkGenerator.committed_paths(ROOT).sort
    files.each { |path, source| assert_equal source, File.read(File.join(ROOT, path), encoding: "UTF-8"), path }
  end

  def test_extended_resources_are_generated_as_a_base_the_hand_written_extension_subclasses
    files = SdkGenerator.generate(SdkGenerator.load_ir(ROOT))

    assert_includes files.fetch("lib/teachmehipaa/resources/events.rb"), "class EventsBase < Core::Resource"
    assert_includes files.fetch("lib/teachmehipaa/resources.rb"), %(require_relative "extensions/events"\n)
    assert_equal TeachMeHipaa::Resources::EventsBase, TeachMeHipaa::Resources::Events.superclass
    assert_instance_of TeachMeHipaa::Resources::Events, build_client(FakeTransport.new).events
    SdkGenerator.extension_files(ROOT).each { |path| assert_path_exists path }
    refute(files.keys.any? { |path| path.include?("/extensions/") })
  end

  private

  def ir
    @ir ||= JSON.parse(File.read(File.join(ROOT, "openapi/sdk-ir.json"), encoding: "UTF-8"))
  end

  def spec_operation_ids
    spec = JSON.parse(File.read(File.join(ROOT, "openapi/openapi.developer.json"), encoding: "UTF-8"))
    spec.fetch("paths").values.flat_map { |item| HTTP_METHODS.filter_map { |verb| item.dig(verb, "operationId") } }
  end

  def ir_methods
    ir.fetch("resources").flat_map do |resource|
      prefix = resource.fetch("path").map { |segment| SdkGenerator::Naming.snake(segment) }
      resource.fetch("methods").map do |method|
        [[*prefix, SdkGenerator::Naming.snake(method.fetch("name"))].join("."), method]
      end
    end
  end

  # Every callable reachable from the client, as "resource.method" => Method.
  # Child resources are the ones held in instance variables.
  # A resource's methods include those of a generated base it extends.
  def public_methods_of(target, prefix = "", owner = TeachMeHipaa::Resources::Root)
    names = own_methods(owner).grep_v(RBS_ALIAS)
    names.sort.each_with_object({}) do |name, found|
      child = target.instance_variable_get(:"@#{name}")
      if child.is_a?(TeachMeHipaa::Core::Resource)
        found.merge!(public_methods_of(child, "#{prefix}#{name}.", child.class))
      else
        found["#{prefix}#{name}"] = unwrapped(target, owner, name)
      end
    end
  end

  # rbs:test wraps each signed method, keeping the original under an alias;
  # the original's parameters are the generated ones.
  def unwrapped(target, owner, name)
    original = own_methods(owner).find { |alias_name| alias_name.start_with?("#{name}__without__") }
    target.method(original || name)
  end

  def own_methods(owner)
    return owner.public_instance_methods(false) unless owner < TeachMeHipaa::Core::Resource

    owner.public_instance_methods - TeachMeHipaa::Core::Resource.public_instance_methods
  end
end
