# frozen_string_literal: true

# Generated from openapi/sdk-ir.json - do not edit. Run `bundle exec rake generate`.

module TeachMeHipaa
  # Tell the variants apart by +type+ or by class. New variants may be added; handle ones you don't
  # recognize.
  module AuditEventActor
    extend Union

    # An AuditEventActor this library doesn't know yet. Its fields are all kept; read them with #[]
    # or #to_h.
    class Unknown < Model
      include AuditEventActor
    end

    variants(
      {
        "agent" => "AuditEventActorAgent",
        "client" => "AuditEventActorClient",
        "scim" => "AuditEventActorScim",
        "user" => "AuditEventActorUser",
      },
      property: "type",
      fallback: "AuditEventActor::Unknown",
    )
  end
end
