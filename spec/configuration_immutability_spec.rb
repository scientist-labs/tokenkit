# frozen_string_literal: true

RSpec.describe "Configuration Immutability" do
  after { TokenKit.reset }

  describe "Configuration class" do
    it "is immutable after creation" do
      config = TokenKit::Configuration.new({
        "strategy" => "unicode",
        "lowercase" => true
      })

      # These should not have setters
      expect(config).not_to respond_to(:strategy=)
      expect(config).not_to respond_to(:lowercase=)
      expect(config).not_to respond_to(:remove_punctuation=)
    end

    it "returns frozen arrays for preserve_patterns" do
      config = TokenKit::Configuration.new({
        "preserve_patterns" => ["pattern1", "pattern2"]
      })

      patterns = config.preserve_patterns
      expect { patterns << "new_pattern" }.to raise_error(FrozenError)
    end

    it "#to_h returns a copy, not the original" do
      hash = {
        "strategy" => "unicode",
        "lowercase" => true
      }

      config = TokenKit::Configuration.new(hash)
      returned_hash = config.to_h

      # Modifying returned hash should not affect config
      returned_hash["strategy"] = "whitespace"
      expect(config.strategy).to eq(:unicode)
    end
  end

  describe "Config singleton" do
    it "modifications persist across calls" do
      TokenKit.config.strategy = :whitespace
      expect(TokenKit.config.strategy).to eq(:whitespace)

      # Should still be whitespace
      expect(TokenKit.config.strategy).to eq(:whitespace)
    end

    it "reset truly resets all values" do
      TokenKit.configure do |config|
        config.strategy = :pattern
        config.regex = /\w+/
        config.lowercase = false
        config.remove_punctuation = true
        config.preserve_patterns = [/test/]
        config.min_gram = 5
        config.max_gram = 15
      end

      TokenKit.reset

      config = TokenKit.config
      expect(config.strategy).to eq(:unicode)
      expect(config.lowercase).to eq(true)
      expect(config.remove_punctuation).to eq(false)
      expect(config.preserve_patterns).to eq([])
      expect(config.min_gram).to eq(2)
      expect(config.max_gram).to eq(10)
    end
  end

  describe "config_hash behavior" do
    it "returns current state snapshot" do
      TokenKit.configure do |config|
        config.strategy = :whitespace
        config.lowercase = false
      end

      config1 = TokenKit.config_hash
      expect(config1.strategy).to eq(:whitespace)
      expect(config1.lowercase).to eq(false)

      # Change configuration
      TokenKit.configure do |config|
        config.strategy = :unicode
        config.lowercase = true
      end

      # Original config object should NOT change (immutable)
      expect(config1.strategy).to eq(:whitespace)
      expect(config1.lowercase).to eq(false)

      # New config object reflects new state
      config2 = TokenKit.config_hash
      expect(config2.strategy).to eq(:unicode)
      expect(config2.lowercase).to eq(true)
    end
  end

  describe "per-call options isolation" do
    it "does not affect global configuration" do
      TokenKit.configure do |config|
        config.strategy = :unicode
        config.lowercase = true
      end

      # Use different options in tokenize call
      tokens = TokenKit.tokenize("Test Text",
        strategy: :whitespace,
        lowercase: false
      )

      # Global config should be unchanged
      expect(TokenKit.config.strategy).to eq(:unicode)
      expect(TokenKit.config.lowercase).to eq(true)
    end

    it "restores configuration after per-call tokenization" do
      TokenKit.configure do |config|
        config.strategy = :unicode
        config.preserve_patterns = [/GENE-\d+/]
      end

      # Per-call with different patterns
      tokens = TokenKit.tokenize("GENE-123 test",
        preserve: [/test/]
      )

      # Next call should use global patterns
      tokens2 = TokenKit.tokenize("GENE-456 test")
      expect(tokens2).to include("GENE-456")
    end
  end

  describe "configuration validation" do
    it "prevents invalid strategy values" do
      expect {
        TokenKit.configure do |config|
          config.strategy = :invalid_strategy
        end
      }.to raise_error(TokenKit::Error, /Invalid strategy/)
    end

    it "validates min_gram and max_gram relationship" do
      expect {
        TokenKit.configure do |config|
          config.strategy = :edge_ngram
          config.min_gram = 10
          config.max_gram = 5
        end
      }.to raise_error(TokenKit::Error, /max_gram .* must be >= min_gram/)
    end
  end

  describe "configuration lifecycle" do
    it "handles config -> tokenize -> reset -> config flow" do
      TokenKit.configure do |config|
        config.strategy = :whitespace
        config.lowercase = false
      end

      tokens1 = TokenKit.tokenize("Test One")
      expect(tokens1).to eq(["Test", "One"])

      TokenKit.reset

      tokens2 = TokenKit.tokenize("Test Two")
      expect(tokens2).to eq(["test", "two"]) # default lowercase: true

      TokenKit.configure do |config|
        config.strategy = :unicode
        config.lowercase = false
      end

      tokens3 = TokenKit.tokenize("Test Three")
      expect(tokens3).to eq(["Test", "Three"])
    end
  end
end