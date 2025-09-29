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

module TokenKit
  class Error < StandardError; end

  extend self

  # Thread-safe storage for current configuration
  @current_config = nil
  @config_mutex = Mutex.new

  def tokenize(text, **opts)
    if opts.any?
      with_temporary_config(opts) do
        _tokenize(text)
      end
    else
      _tokenize(text)
    end
  end

  # Get current configuration
  # Returns the Config singleton for backward compatibility
  def config
    Config.instance
  end

  # Get current configuration as immutable Configuration object
  def config_hash
    @config_mutex.synchronize do
      @current_config ||= ConfigBuilder.new.build
    end
  end

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

  def with_temporary_config(opts)
    # Save current Rust config
    previous_config = _config_hash

    # Build temporary config
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

    temp_config = builder.build
    _configure(temp_config.to_rust_config)

    yield
  ensure
    # Restore previous config
    _load_config(previous_config) if previous_config
  end

  def _tokenize(text)
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
