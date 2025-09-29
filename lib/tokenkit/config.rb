module TokenKit
  class Config
    attr_accessor :strategy, :regex, :grapheme_extended, :min_gram, :max_gram, :delimiter, :split_on_chars, :lowercase, :remove_punctuation, :preserve_patterns

    def self.instance
      @instance ||= new
    end

    def initialize
      @strategy = :unicode
      @lowercase = true
      @remove_punctuation = false
      @preserve_patterns = []
      @grapheme_extended = true
      @min_gram = 2
      @max_gram = 10
      @delimiter = "/"
      @split_on_chars = " \t\n\r"
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

      if strategy == :grapheme
        config_hash["extended"] = grapheme_extended
      end

      if strategy == :edge_ngram || strategy == :ngram
        config_hash["min_gram"] = min_gram
        config_hash["max_gram"] = max_gram
      end

      if strategy == :path_hierarchy
        config_hash["delimiter"] = delimiter
      end

      if strategy == :char_group
        config_hash["split_on_chars"] = split_on_chars
      end

      TokenKit.configure(config_hash)
    end

    def to_h
      {
        strategy: strategy,
        regex: regex,
        grapheme_extended: grapheme_extended,
        min_gram: min_gram,
        max_gram: max_gram,
        delimiter: delimiter,
        split_on_chars: split_on_chars,
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
