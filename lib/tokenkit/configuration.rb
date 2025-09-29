module TokenKit
  # Immutable configuration object representing tokenizer settings.
  #
  # This class provides read-only access to configuration values and
  # convenient predicate methods for checking the current strategy.
  #
  # @example Access configuration
  #   config = TokenKit.config_hash
  #   config.strategy           # => :unicode
  #   config.lowercase          # => true
  #   config.preserve_patterns  # => [/\d+mg/i]
  #
  # @example Check strategy type
  #   config.unicode?           # => true
  #   config.edge_ngram?        # => false
  #
  class Configuration
    # @return [Symbol] The tokenization strategy
    attr_reader :strategy

    # @return [Boolean] Whether to lowercase tokens
    attr_reader :lowercase

    # @return [Boolean] Whether to remove punctuation
    attr_reader :remove_punctuation

    # @return [Array<Regexp>] Patterns to preserve from modification
    attr_reader :preserve_patterns

    # Creates a new configuration from a hash.
    #
    # @param config_hash [Hash] Configuration values from Rust
    # @api private
    #
    def initialize(config_hash)
      @strategy = config_hash["strategy"]&.to_sym || :unicode
      @lowercase = config_hash.fetch("lowercase", true)
      @remove_punctuation = config_hash.fetch("remove_punctuation", false)
      @preserve_patterns = config_hash.fetch("preserve_patterns", []).freeze
      @raw_hash = config_hash
    end

    # @return [Boolean] true if using pattern tokenization strategy
    def pattern?
      strategy == :pattern
    end

    # @return [String, nil] The regex pattern for pattern strategy
    def regex
      @raw_hash["regex"]
    end

    # @return [Boolean] true if using grapheme tokenization strategy
    def grapheme?
      strategy == :grapheme
    end

    # @return [Boolean, nil] Whether to use extended grapheme clusters
    def extended
      @raw_hash["extended"]
    end

    # @return [Boolean] true if using edge n-gram tokenization strategy
    def edge_ngram?
      strategy == :edge_ngram
    end

    # @return [Integer, nil] Minimum n-gram size for n-gram strategies
    def min_gram
      @raw_hash["min_gram"]
    end

    # @return [Integer, nil] Maximum n-gram size for n-gram strategies
    def max_gram
      @raw_hash["max_gram"]
    end

    # @return [Boolean] true if using path hierarchy tokenization strategy
    def path_hierarchy?
      strategy == :path_hierarchy
    end

    # @return [String, nil] Delimiter for path hierarchy strategy
    def delimiter
      @raw_hash["delimiter"]
    end

    # @return [Boolean] true if using n-gram tokenization strategy
    def ngram?
      strategy == :ngram
    end

    # @return [Boolean] true if using character group tokenization strategy
    def char_group?
      strategy == :char_group
    end

    # @return [String, nil] Characters to split on for char_group strategy
    def split_on_chars
      @raw_hash["split_on_chars"]
    end

    # @return [Boolean] true if using letter tokenization strategy
    def letter?
      strategy == :letter
    end

    # @return [Boolean] true if using lowercase tokenization strategy
    def lowercase?
      strategy == :lowercase
    end

    # @return [Boolean] true if using unicode tokenization strategy
    def unicode?
      strategy == :unicode
    end

    # @return [Boolean] true if using whitespace tokenization strategy
    def whitespace?
      strategy == :whitespace
    end

    # @return [Boolean] true if using sentence tokenization strategy
    def sentence?
      strategy == :sentence
    end

    # @return [Boolean] true if using keyword tokenization strategy
    def keyword?
      strategy == :keyword
    end

    # @return [Boolean] true if using url_email tokenization strategy
    def url_email?
      strategy == :url_email
    end

    # Converts configuration to a hash.
    #
    # @return [Hash] Configuration as a hash
    #
    # @example
    #   config.to_h
    #   # => {"strategy" => "unicode", "lowercase" => true, ...}
    #
    def to_h
      @raw_hash.dup
    end

    # Returns a string representation of the configuration.
    #
    # @return [String] Human-readable configuration summary
    #
    def inspect
      "#<TokenKit::Configuration strategy=#{strategy} lowercase=#{lowercase} remove_punctuation=#{remove_punctuation}>"
    end

    # Converts configuration to format expected by Rust.
    #
    # @return [Hash] Configuration hash for Rust FFI
    # @api private
    #
    def to_rust_config
      @raw_hash
    end

    # Creates a ConfigBuilder from this configuration for modification.
    #
    # @return [ConfigBuilder] A builder initialized with this configuration
    #
    # @example
    #   builder = config.to_builder
    #   builder.lowercase = false
    #   new_config = builder.build
    #
    def to_builder
      builder = ConfigBuilder.new
      builder.strategy = strategy
      builder.lowercase = lowercase
      builder.remove_punctuation = remove_punctuation
      builder.preserve_patterns = preserve_patterns.dup

      # Copy strategy-specific settings
      builder.regex = regex if pattern?
      builder.extended = extended if grapheme?
      builder.min_gram = min_gram if edge_ngram? || ngram?
      builder.max_gram = max_gram if edge_ngram? || ngram?
      builder.delimiter = delimiter if path_hierarchy?
      builder.split_on_chars = split_on_chars if char_group?

      builder
    end
  end
end
