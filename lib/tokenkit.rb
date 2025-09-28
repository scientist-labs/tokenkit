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

    if Config.instance.strategy == :pattern && Config.instance.regex
      config_hash["regex"] = Config.instance.regex
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
  end

  def config_hash
    _config_hash
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
    _configure(temp_config)
    yield
  ensure
    _load_config(previous_config)
  end

  def normalize_options(opts)
    normalized = {}
    normalized["strategy"] = opts[:strategy].to_s if opts[:strategy]
    normalized["regex"] = opts[:regex] if opts[:regex]
    normalized["lowercase"] = opts[:lowercase] if opts.key?(:lowercase)
    normalized["remove_punctuation"] = opts[:remove_punctuation] if opts.key?(:remove_punctuation)

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
