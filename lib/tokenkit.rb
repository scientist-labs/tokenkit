# frozen_string_literal: true

require_relative "tokenkit/version"

begin
  RUBY_VERSION =~ /(\d+\.\d+)/
  require_relative "tokenkit/#{Regexp.last_match(1)}/tokenkit"
rescue LoadError
  require_relative "tokenkit/tokenkit"
end

module TokenKit
  class Error < StandardError; end

  extend self

  def tokenize(text, **opts)
    if opts.any?
      with_temporary_config(opts) do
        _tokenize(text)
      end
    else
      _tokenize(text)
    end
  end

  def configure
    yield Config.instance if block_given?
    config_hash = {
      "strategy" => Config.instance.strategy.to_s,
      "lowercase" => Config.instance.lowercase,
      "remove_punctuation" => Config.instance.remove_punctuation,
      "preserve_patterns" => Config.instance.preserve_patterns.map { |p| p.is_a?(Regexp) ? regex_to_rust(p) : p.to_s }
    }

    # Warn if lowercase: false with :lowercase strategy
    if Config.instance.strategy == :lowercase && !Config.instance.lowercase
      warn "Warning: The :lowercase strategy always lowercases text. The 'lowercase: false' setting will be ignored."
    end

    if Config.instance.strategy == :pattern && Config.instance.regex
      regex = Config.instance.regex
      config_hash["regex"] = regex.is_a?(Regexp) ? regex_to_rust(regex) : regex.to_s
    end

    if Config.instance.strategy == :grapheme
      config_hash["extended"] = Config.instance.grapheme_extended
    end

    if Config.instance.strategy == :edge_ngram || Config.instance.strategy == :ngram
      config_hash["min_gram"] = Config.instance.min_gram
      config_hash["max_gram"] = Config.instance.max_gram
    end

    if Config.instance.strategy == :path_hierarchy
      config_hash["delimiter"] = Config.instance.delimiter
    end

    if Config.instance.strategy == :char_group
      config_hash["split_on_chars"] = Config.instance.split_on_chars
    end

    _configure(config_hash)
  end

  def config
    Config.instance
  end

  def reset
    _reset
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

  def config_hash
    Configuration.new(_config_hash)
  end

  private

  def regex_to_rust(pattern)
    flags = ""
    flags += "i" if (pattern.options & Regexp::IGNORECASE) != 0
    flags += "m" if (pattern.options & Regexp::MULTILINE) != 0
    flags += "x" if (pattern.options & Regexp::EXTENDED) != 0

    if flags.empty?
      pattern.source
    else
      "(?#{flags})#{pattern.source}"
    end
  end

  def with_temporary_config(opts)
    previous_config = _config_hash
    temp_config = previous_config.merge(normalize_options(opts))

    # Warn if lowercase: false with :lowercase strategy
    if temp_config["strategy"] == "lowercase" && temp_config["lowercase"] == false
      warn "Warning: The :lowercase strategy always lowercases text. The 'lowercase: false' setting will be ignored."
    end

    _configure(temp_config)
    yield
  ensure
    _load_config(previous_config)
  end

  def normalize_options(opts)
    normalized = {}

    [:extended, :min_gram, :max_gram, :delimiter, :split_on_chars, :lowercase, :remove_punctuation].each do |key|
      normalized[key.to_s] = opts[key] if opts.key?(key)
    end

    normalized["strategy"] = opts[:strategy].to_s if opts[:strategy]

    if opts[:regex]
      regex = opts[:regex]
      normalized["regex"] = regex.is_a?(Regexp) ? regex_to_rust(regex) : regex.to_s
    end

    if opts[:preserve]
      normalized["preserve_patterns"] = Array(opts[:preserve]).map do |pattern|
        pattern.is_a?(Regexp) ? regex_to_rust(pattern) : pattern.to_s
      end
    end

    normalized
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

require_relative "tokenkit/config"
require_relative "tokenkit/configuration"
