# frozen_string_literal: true

module SdkGenerator
  # Naming rules. The IR gives camelCase resource, method and field names
  # and PascalCase type names; these derive the Ruby names from them.
  module Naming
    RUBY_KEYWORDS = %w[
      BEGIN END alias and begin break case class def defined? do else elsif end ensure false for if in module
      next nil not or redo rescue retry return self super then true undef unless until when while yield
    ].freeze

    module_function

    def snake(name)
      name.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
    end

    def pascal(name)
      name[0].upcase + name[1..]
    end

    # An enum value as a constant name: "api_client.created" and
    # "apiClientCreated" both become API_CLIENT_CREATED.
    def constant(value)
      name = snake(value).upcase.gsub(/[^A-Z\d]+/, "_").delete_prefix("_").delete_suffix("_")
      name.match?(/\A[A-Z]/) ? name : "V_#{name}"
    end

    # English singular of a camelCase resource segment. The IR has no
    # singular names, so this covers the plural forms resource names use.
    def singular(name)
      return "#{name.delete_suffix("ies")}y" if name.end_with?("ies")
      return name.delete_suffix("es") if name.end_with?("sses")
      return name.delete_suffix("s") if name.end_with?("s") && !name.end_with?("ss")

      name
    end

    # ["webhookSubscriptions", "deliveries"] becomes WebhookSubscriptionDeliveries.
    def resource_class(path)
      path.each_with_index.map { |segment, i| pascal(i == path.length - 1 ? segment : singular(segment)) }.join
    end

    # A keyword parameter named after a Ruby keyword (audit events'
    # +until:+) is legal but can't be read as a local variable.
    def keyword?(name)
      RUBY_KEYWORDS.include?(name)
    end

    # How generated code reads the parameter +name+.
    def read_parameter(name)
      keyword?(name) ? "binding.local_variable_get(:#{name})" : name
    end
  end
end
