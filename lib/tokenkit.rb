# frozen_string_literal: true

require_relative "tokenkit/version"
require_relative "tokenkit/regex_converter"
require_relative "tokenkit/config_builder"
require_relative "tokenkit/config_compat"

begin
  RUBY_VERSION =~ /(\d+\.\d+)/
  require_relative "tokenkit/#{Regexp.last_match(1)}/tokenkit"
rescue LoadError
  require_relative "tokenkit/tokenkit"
end

# TokenKit provides fast, Rust-backed tokenization for Ruby with pattern preservation.
#
# @example Basic usage
#   TokenKit.tokenize("Hello, world!")
#   # => ["hello", "world"]
#
# @example Configuration
#   TokenKit.configure do |config|
#     config.strategy = :unicode
#     config.lowercase = true
#     config.preserve_patterns = [/\d+mg/i]
#   end
#
# @example Instance-based tokenization
#   tokenizer = TokenKit::Tokenizer.new(strategy: :unicode)
#   tokenizer.tokenize("test text")
#
module TokenKit
  # Base error class for TokenKit exceptions
  class Error < StandardError; end

  # Instance-based tokenizer for thread-safe tokenization with specific configuration.
  #
  # @example Create a tokenizer with custom config
  #   tokenizer = TokenKit::Tokenizer.new(
  #     strategy: :unicode,
  #     lowercase: true,
  #     preserve_patterns: [/\d+mg/i]
  #   )
  #   tokenizer.tokenize("Patient received 100mg")
  #   # => ["patient", "received", "100mg"]
  #
  class Tokenizer
    # @return [Configuration] The tokenizer's configuration
    attr_reader :config

    # Creates a new tokenizer instance with the specified configuration.
    #
    # @param config [Hash, Configuration, ConfigBuilder] The configuration for this tokenizer
    # @option config [Symbol] :strategy (:unicode) The tokenization strategy
    # @option config [Boolean] :lowercase (true) Whether to lowercase tokens
    # @option config [Boolean] :remove_punctuation (false) Whether to remove punctuation
    # @option config [Array<Regexp>] :preserve_patterns ([]) Patterns to preserve
    #
    # @example With hash configuration
    #   tokenizer = TokenKit::Tokenizer.new(strategy: :whitespace)
    #
    # @example With existing configuration
    #   config = TokenKit.config_hash
    #   tokenizer = TokenKit::Tokenizer.new(config)
    #
    def initialize(config = {})
      @config = if config.is_a?(Configuration)
        config
      elsif config.is_a?(ConfigBuilder)
        config.build
      elsif config.is_a?(Hash)
        builder = TokenKit.config_hash.to_builder
        config.each do |key, value|
          builder.send("#{key}=", value) if builder.respond_to?("#{key}=")
        end
        builder.build
      else
        TokenKit.config_hash
      end
    end

    # Tokenizes the given text using this tokenizer's configuration.
    #
    # @param text [String] The text to tokenize
    # @return [Array<String>] An array of tokens
    #
    # @example
    #   tokenizer = TokenKit::Tokenizer.new(strategy: :unicode)
    #   tokenizer.tokenize("Hello world")
    #   # => ["hello", "world"]
    #
    def tokenize(text)
      TokenKit._tokenize_with_config(text, @config.to_rust_config)
    end
  end

  extend self

  # Thread-safe storage for current configuration
  @current_config = nil
  @config_mutex = Mutex.new

  # Tokenizes text using the global configuration or with temporary overrides.
  #
  # @param text [String] The text to tokenize
  # @param opts [Hash] Optional configuration overrides for this tokenization only
  # @option opts [Symbol] :strategy The tokenization strategy to use
  # @option opts [Boolean] :lowercase Whether to lowercase tokens
  # @option opts [Boolean] :remove_punctuation Whether to remove punctuation
  # @option opts [Array<Regexp>] :preserve_patterns Patterns to preserve
  # @option opts [String, Regexp] :regex Pattern for :pattern strategy
  # @option opts [Integer] :min_gram Minimum n-gram size (for n-gram strategies)
  # @option opts [Integer] :max_gram Maximum n-gram size (for n-gram strategies)
  # @option opts [String] :delimiter Delimiter for :path_hierarchy strategy
  # @option opts [String] :split_on_chars Characters to split on for :char_group strategy
  # @option opts [Boolean] :extended Extended grapheme clusters for :grapheme strategy
  #
  # @return [Array<String>] An array of tokens
  #
  # @example Basic tokenization
  #   TokenKit.tokenize("Hello, world!")
  #   # => ["hello", "world"]
  #
  # @example With temporary overrides
  #   TokenKit.tokenize("Hello World", lowercase: false)
  #   # => ["Hello", "World"]
  #
  # @example With strategy override
  #   TokenKit.tokenize("test-case", strategy: :char_group, split_on_chars: "-")
  #   # => ["test", "case"]
  #
  def tokenize(text, **opts)
    if opts.any?
      # Create a fresh tokenizer with merged config
      merged_config = build_merged_config(opts)
      _tokenize_with_config(text, merged_config)
    else
      # Use default config (creates fresh tokenizer internally)
      _tokenize(text)
    end
  end

  # Returns the global configuration object for backward compatibility.
  #
  # @deprecated Use {#config_hash} for read-only access or {#configure} to modify
  # @return [Config] The global configuration singleton
  #
  # @example
  #   TokenKit.config.strategy = :unicode  # Deprecated
  #
  def config
    Config.instance
  end

  # Returns the current global configuration as an immutable object.
  #
  # @return [Configuration] The current configuration with accessor methods
  #
  # @example Get current configuration
  #   config = TokenKit.config_hash
  #   config.strategy          # => :unicode
  #   config.lowercase         # => true
  #   config.preserve_patterns # => []
  #
  # @example Check strategy type
  #   config = TokenKit.config_hash
  #   config.unicode?          # => true
  #   config.edge_ngram?       # => false
  #
  def config_hash
    @config_mutex.synchronize do
      @current_config ||= ConfigBuilder.new.build
    end
  end

  # Configures the global tokenizer settings.
  #
  # @yield [Config] Yields the configuration object for modification
  # @return [Configuration] The new configuration
  #
  # @raise [ArgumentError] If invalid configuration is provided
  # @raise [RegexpError] If invalid regex pattern is provided
  #
  # @example Basic configuration
  #   TokenKit.configure do |config|
  #     config.strategy = :unicode
  #     config.lowercase = true
  #   end
  #
  # @example With pattern preservation
  #   TokenKit.configure do |config|
  #     config.strategy = :unicode
  #     config.preserve_patterns = [
  #       /\d+mg/i,            # Measurements
  #       /[A-Z]{2,}/,         # Acronyms
  #       /\w+@\w+\.\w+/      # Emails
  #     ]
  #   end
  #
  # @example Edge n-gram configuration
  #   TokenKit.configure do |config|
  #     config.strategy = :edge_ngram
  #     config.min_gram = 2
  #     config.max_gram = 10
  #   end
  #
  def configure
    # Use the compatibility wrapper to support old API
    yield Config.instance if block_given?

    # Get the builder from the compatibility wrapper
    builder = Config.instance.build_config

    begin
      # Build and validate the new configuration
      new_config = builder.build

      # Apply to Rust tokenizer
      _configure(new_config.to_rust_config)

      # Store the new configuration
      @config_mutex.synchronize do
        @current_config = new_config
      end

      # Reset the compatibility wrapper
      Config.instance.reset_temp

      new_config
    rescue => e
      # Reset the compatibility wrapper on error
      Config.instance.reset_temp
      raise e
    end
  end

  # Resets the tokenizer to default configuration.
  #
  # @return [void]
  #
  # @example
  #   TokenKit.reset
  #   # Configuration is now:
  #   # - strategy: :unicode
  #   # - lowercase: true
  #   # - remove_punctuation: false
  #   # - preserve_patterns: []
  #
  def reset
    # Create default configuration
    new_config = ConfigBuilder.new.build

    # Reset Rust tokenizer
    _reset
    _configure(new_config.to_rust_config)

    # Store the new configuration
    @config_mutex.synchronize do
      @current_config = new_config
    end

    # Reset the compatibility wrapper
    Config.instance.reset_temp

    # Reset Config singleton instance variables for backward compatibility
    Config.instance.instance_variable_set(:@strategy, :unicode)
    Config.instance.instance_variable_set(:@lowercase, true)
    Config.instance.instance_variable_set(:@remove_punctuation, false)
    Config.instance.instance_variable_set(:@preserve_patterns, [])
    Config.instance.instance_variable_set(:@grapheme_extended, true)
    Config.instance.instance_variable_set(:@min_gram, 2)
    Config.instance.instance_variable_set(:@max_gram, 10)
    Config.instance.instance_variable_set(:@delimiter, "/")
    Config.instance.instance_variable_set(:@split_on_chars, " \t\n\r")
  end

  private

  def build_merged_config(opts)
    # Build config with options merged in
    builder = config_hash.to_builder

    # Apply options to builder
    opts.each do |key, value|
      case key
      when :strategy
        builder.strategy = value
      when :lowercase
        builder.lowercase = value
      when :remove_punctuation
        builder.remove_punctuation = value
      when :preserve, :preserve_patterns
        patterns = Array(value)
        builder.preserve_patterns = patterns
      when :regex
        builder.regex = value
      when :extended, :grapheme_extended
        builder.grapheme_extended = value
      when :min_gram
        builder.min_gram = value
      when :max_gram
        builder.max_gram = value
      when :delimiter
        builder.delimiter = value
      when :split_on_chars
        builder.split_on_chars = value
      end
    end

    builder.build.to_rust_config
  end

  def _tokenize(text)
    raise NotImplementedError, "Native extension not loaded"
  end

  def _tokenize_with_config(text, config_hash)
    raise NotImplementedError, "Native extension not loaded"
  end

  def _configure(hash)
    raise NotImplementedError, "Native extension not loaded"
  end

  def _reset
    raise NotImplementedError, "Native extension not loaded"
  end

  def _config_hash
    raise NotImplementedError, "Native extension not loaded"
  end

  def _load_config(hash)
    raise NotImplementedError, "Native extension not loaded"
  end
end
