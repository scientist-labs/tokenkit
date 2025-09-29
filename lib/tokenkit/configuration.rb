module TokenKit
  class Configuration
    attr_reader :strategy, :lowercase, :remove_punctuation, :preserve_patterns

    def initialize(config_hash)
      @strategy = config_hash["strategy"]&.to_sym || :unicode
      @lowercase = config_hash.fetch("lowercase", true)
      @remove_punctuation = config_hash.fetch("remove_punctuation", false)
      @preserve_patterns = config_hash.fetch("preserve_patterns", [])
      @raw_hash = config_hash
    end

    def pattern?
      strategy == :pattern
    end

    def regex
      @raw_hash["regex"]
    end

    def grapheme?
      strategy == :grapheme
    end

    def extended
      @raw_hash["extended"]
    end

    def edge_ngram?
      strategy == :edge_ngram
    end

    def min_gram
      @raw_hash["min_gram"]
    end

    def max_gram
      @raw_hash["max_gram"]
    end

    def path_hierarchy?
      strategy == :path_hierarchy
    end

    def delimiter
      @raw_hash["delimiter"]
    end

    def ngram?
      strategy == :ngram
    end

    def char_group?
      strategy == :char_group
    end

    def split_on_chars
      @raw_hash["split_on_chars"]
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

    def inspect
      "#<TokenKit::Configuration strategy=#{strategy} lowercase=#{lowercase} remove_punctuation=#{remove_punctuation}>"
    end
  end
end
