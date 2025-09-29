# frozen_string_literal: true

require_relative 'regex_converter'

module TokenKit
  # Builder for creating immutable Configuration objects
  class ConfigBuilder
    attr_accessor :strategy, :lowercase, :remove_punctuation, :preserve_patterns
    attr_accessor :regex, :grapheme_extended, :min_gram, :max_gram
    attr_accessor :delimiter, :split_on_chars

    # Default values
    DEFAULTS = {
      strategy: :unicode,
      lowercase: true,
      remove_punctuation: false,
      preserve_patterns: [],
      grapheme_extended: true,
      min_gram: 2,
      max_gram: 10,
      delimiter: "/",
      split_on_chars: " \t\n\r"
    }.freeze

    VALID_STRATEGIES = [
      :unicode, :whitespace, :pattern, :sentence, :grapheme, :keyword,
      :edge_ngram, :ngram, :path_hierarchy, :url_email, :char_group,
      :letter, :lowercase
    ].freeze

    def initialize(base_config = nil)
      if base_config
        # Copy from existing config
        @strategy = base_config.strategy
        @lowercase = base_config.lowercase
        @remove_punctuation = base_config.remove_punctuation
        @preserve_patterns = base_config.preserve_patterns.dup
        @regex = base_config.instance_variable_get(:@regex) if base_config.instance_variable_defined?(:@regex)
        @grapheme_extended = base_config.instance_variable_get(:@grapheme_extended) || DEFAULTS[:grapheme_extended]
        @min_gram = base_config.instance_variable_get(:@min_gram) || DEFAULTS[:min_gram]
        @max_gram = base_config.instance_variable_get(:@max_gram) || DEFAULTS[:max_gram]
        @delimiter = base_config.instance_variable_get(:@delimiter) || DEFAULTS[:delimiter]
        @split_on_chars = base_config.instance_variable_get(:@split_on_chars) || DEFAULTS[:split_on_chars]
      else
        # Start with defaults
        DEFAULTS.each do |key, value|
          instance_variable_set("@#{key}", value.is_a?(Array) ? value.dup : value)
        end
      end
    end

    # Build an immutable Configuration object
    # @return [Configuration] The built configuration
    # @raise [Error] if configuration is invalid
    def build
      validate!

      config_hash = build_config_hash
      Configuration.new(config_hash, self)
    end

    private

    def validate!
      # Validate strategy
      unless VALID_STRATEGIES.include?(@strategy)
        raise Error, "Invalid strategy: #{@strategy}. Valid strategies are: #{VALID_STRATEGIES.join(', ')}"
      end

      # Strategy-specific validations
      case @strategy
      when :pattern
        raise Error, "Pattern strategy requires a regex" unless @regex
        if @regex.is_a?(String)
          RegexConverter.validate!(@regex)
        end
      when :edge_ngram, :ngram
        raise Error, "min_gram must be positive, got #{@min_gram}" if @min_gram < 1
        raise Error, "max_gram (#{@max_gram}) must be >= min_gram (#{@min_gram})" if @max_gram < @min_gram
      when :path_hierarchy
        raise Error, "Path hierarchy requires a delimiter" if @delimiter.nil? || @delimiter.empty?
      when :lowercase
        # Warn if lowercase: false with :lowercase strategy
        if !@lowercase
          warn "Warning: The :lowercase strategy always lowercases text. The 'lowercase: false' setting will be ignored."
        end
      end
    end

    def build_config_hash
      config = {
        "strategy" => @strategy.to_s,
        "lowercase" => @lowercase,
        "remove_punctuation" => @remove_punctuation,
        "preserve_patterns" => RegexConverter.patterns_to_rust(@preserve_patterns)
      }

      # Add strategy-specific parameters
      case @strategy
      when :pattern
        config["regex"] = @regex.is_a?(Regexp) ? RegexConverter.to_rust(@regex) : @regex.to_s
      when :grapheme
        config["extended"] = @grapheme_extended
      when :edge_ngram, :ngram
        config["min_gram"] = @min_gram
        config["max_gram"] = @max_gram
      when :path_hierarchy
        config["delimiter"] = @delimiter
      when :char_group
        config["split_on_chars"] = @split_on_chars
      end

      config
    end
  end

  # Immutable configuration object
  class Configuration
    attr_reader :strategy, :lowercase, :remove_punctuation, :preserve_patterns
    attr_reader :regex, :grapheme_extended, :min_gram, :max_gram, :delimiter, :split_on_chars

    def initialize(config_hash, builder = nil)
      @strategy = config_hash["strategy"]&.to_sym || :unicode
      @lowercase = config_hash.fetch("lowercase", true)
      @remove_punctuation = config_hash.fetch("remove_punctuation", false)
      @preserve_patterns = config_hash.fetch("preserve_patterns", []).freeze
      @raw_hash = config_hash.freeze

      # Store builder data for creating new builders from this config
      if builder
        @regex = builder.regex
        @grapheme_extended = builder.grapheme_extended
        @min_gram = builder.min_gram
        @max_gram = builder.max_gram
        @delimiter = builder.delimiter
        @split_on_chars = builder.split_on_chars
      else
        # Extract from raw_hash for backward compatibility
        @regex = config_hash["regex"]
        @grapheme_extended = config_hash["extended"] || ConfigBuilder::DEFAULTS[:grapheme_extended]
        @min_gram = config_hash["min_gram"] || ConfigBuilder::DEFAULTS[:min_gram]
        @max_gram = config_hash["max_gram"] || ConfigBuilder::DEFAULTS[:max_gram]
        @delimiter = config_hash["delimiter"] || ConfigBuilder::DEFAULTS[:delimiter]
        @split_on_chars = config_hash["split_on_chars"] || ConfigBuilder::DEFAULTS[:split_on_chars]
      end
    end

    # Create a new builder initialized with this configuration
    def to_builder
      ConfigBuilder.new(self)
    end

    # Strategy-specific accessors
    def pattern?
      strategy == :pattern
    end

    def grapheme?
      strategy == :grapheme
    end

    def extended
      @grapheme_extended
    end

    def edge_ngram?
      strategy == :edge_ngram
    end

    def ngram?
      strategy == :ngram
    end

    def path_hierarchy?
      strategy == :path_hierarchy
    end

    def char_group?
      strategy == :char_group
    end

    def letter?
      strategy == :letter
    end

    def lowercase?
      strategy == :lowercase
    end

    def to_h
      @raw_hash.dup
    end

    def to_rust_config
      @raw_hash
    end

    def inspect
      "#<TokenKit::Configuration strategy=#{strategy} lowercase=#{lowercase} remove_punctuation=#{remove_punctuation}>"
    end

    # Check equality with another configuration
    def ==(other)
      other.is_a?(Configuration) && to_h == other.to_h
    end
  end
end