module TokenKit
  class Config
    attr_accessor :strategy, :regex, :lowercase, :remove_punctuation, :preserve_patterns

    def self.instance
      @instance ||= new
    end

    def initialize
      @strategy = :unicode
      @lowercase = true
      @remove_punctuation = false
      @preserve_patterns = []
    end

    def apply!
      config_hash = {
        "strategy" => strategy.to_s,
        "lowercase" => lowercase,
        "remove_punctuation" => remove_punctuation,
        "preserve_patterns" => preserve_patterns.map { |p| pattern_to_string(p) }
      }

      if strategy == :pattern && regex
        config_hash["regex"] = regex
      end

      TokenKit.configure(config_hash)
    end

    def to_h
      {
        strategy: strategy,
        regex: regex,
        lowercase: lowercase,
        remove_punctuation: remove_punctuation,
        preserve_patterns: preserve_patterns
      }.compact
    end

    private

    def pattern_to_string(pattern)
      pattern.is_a?(Regexp) ? pattern.source : pattern.to_s
    end
  end
end