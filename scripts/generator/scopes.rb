# frozen_string_literal: true

module SdkGenerator
  # The Scopes an Access token needs to call a method. The IR's
  # +security.anyOf+ lists alternative sets, each of Scopes needed together;
  # [[]] means any Access token will do.
  module Scopes
    module_function

    def sets(method)
      method.public? ? [] : method.data.dig("security", "anyOf")
    end

    def any_token?(method)
      !method.public? && sets(method).all?(&:empty?)
    end

    # "a or b", "a and b", each Scope formatted by the block.
    def phrase(method, &format)
      sets(method).map { |set| set.map(&format).join(" and ") }.join(" or ")
    end

    # The sentence a method's doc comment ends with; nil for a public method.
    def note(method)
      return nil if method.public?
      return "Works with any Access token, whatever its Scopes." if any_token?(method)

      plural = sets(method).any? { |set| set.length > 1 } ? "s" : ""
      "Needs the #{phrase(method) { |scope| "+#{scope}+" }} Scope#{plural}."
    end
  end
end
