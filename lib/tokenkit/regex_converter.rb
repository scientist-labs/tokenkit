# frozen_string_literal: true

module TokenKit
  # Converts Ruby Regexp objects to Rust-compatible regex strings
  module RegexConverter
    extend self

    # Convert a Ruby Regexp to Rust regex syntax
    # @param pattern [Regexp, String] The pattern to convert
    # @return [String] Rust-compatible regex string
    def to_rust(pattern)
      return pattern.to_s unless pattern.is_a?(Regexp)

      flags = extract_flags(pattern)
      source = pattern.source

      if flags.empty?
        source
      else
        "(?#{flags})#{source}"
      end
    end

    # Convert an array of patterns to Rust regex strings
    # @param patterns [Array<Regexp, String>] The patterns to convert
    # @return [Array<String>] Rust-compatible regex strings
    def patterns_to_rust(patterns)
      return [] unless patterns

      patterns.map { |p| to_rust(p) }
    end

    # Validate a regex pattern
    # @param pattern [String] The regex pattern to validate
    # @return [Boolean] true if valid
    # @raise [Error] if invalid
    def validate!(pattern)
      # Try to compile it in Ruby first
      Regexp.new(pattern)
      true
    rescue RegexpError => e
      raise Error, "Invalid regex pattern '#{pattern}': #{e.message}"
    end

    private

    # Extract flags from a Ruby Regexp
    # @param regexp [Regexp] The regexp to extract flags from
    # @return [String] Rust-compatible flag string
    def extract_flags(regexp)
      flags = ""
      flags += "i" if (regexp.options & Regexp::IGNORECASE) != 0
      flags += "m" if (regexp.options & Regexp::MULTILINE) != 0
      flags += "x" if (regexp.options & Regexp::EXTENDED) != 0
      flags
    end
  end
end