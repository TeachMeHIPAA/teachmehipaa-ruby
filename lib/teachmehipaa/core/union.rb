# frozen_string_literal: true

module TeachMeHipaa
  # Generated union modules (an AuditEvent, an Event) extend this. Every
  # variant class includes its union module, so
  # <tt>case event when TeachMeHipaa::AuditEventCertificateIssued</tt> and
  # <tt>event.is_a?(TeachMeHipaa::AuditEvent)</tt> both work.
  #
  # Reading never raises for a variant newer than the library: it falls back
  # to the union's generic class, which keeps every field (ADR-0006).
  module Union
    # Reads +data+ into the variant class its discriminator names.
    def new(data, last_response: nil)
      TeachMeHipaa.const_get(variant_name(data)).new(data, last_response:)
    end

    # The API's JSON for +params+, converted by the variant they describe.
    def to_wire(params)
      name = variant_name(params.transform_keys(&:to_s), snake_keys: true)
      return Core::Values.write_object(nil, params) if name.nil?

      TeachMeHipaa.const_get(name).to_wire(params)
    end

    private

    # +variants+ maps a discriminator value (or, without +property+, the
    # field whose presence picks the variant) to a class name under
    # TeachMeHipaa. +fallback+ names the class for anything else.
    def variants(variants, fallback:, property: nil)
      @variants = variants.freeze
      @fallback = fallback
      @property = property
    end

    def variant_name(data, snake_keys: false)
      key = if @property
              lookup(data, @property, snake_keys)
            else
              @variants.keys.find { |name| !lookup(data, name, snake_keys).nil? }
            end
      @variants.fetch(key) { snake_keys ? nil : @fallback }
    end

    def lookup(data, wire_name, snake_keys)
      data.fetch(wire_name) do
        data[wire_name.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase] if snake_keys
      end
    end
  end
end
