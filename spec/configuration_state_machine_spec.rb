# frozen_string_literal: true

RSpec.describe "Configuration State Machine" do
  before { TokenKit.reset }
  after { TokenKit.reset }

  describe "valid state transitions" do
    it "transitions from default to configured state" do
      # Start in default state
      expect(TokenKit.config.strategy).to eq(:unicode)
      expect(TokenKit.config.lowercase).to eq(true)

      # Transition to configured state
      TokenKit.configure do |config|
        config.strategy = :whitespace
        config.lowercase = false
      end

      expect(TokenKit.config.strategy).to eq(:whitespace)
      expect(TokenKit.config.lowercase).to eq(false)

      # Verify tokenizer works in new state
      tokens = TokenKit.tokenize("Test Text")
      expect(tokens).to eq(["Test", "Text"])
    end

    it "transitions between different strategies" do
      strategies = [:unicode, :whitespace, :letter, :sentence, :keyword]

      strategies.each do |strategy|
        TokenKit.configure { |c| c.strategy = strategy }
        expect(TokenKit.config.strategy).to eq(strategy)

        # Verify tokenization works
        tokens = TokenKit.tokenize("test text")
        expect(tokens).to be_a(Array)
      end
    end

    it "handles configure -> tokenize -> configure cycle" do
      # First configuration
      TokenKit.configure do |config|
        config.strategy = :whitespace
        config.lowercase = false
      end

      tokens1 = TokenKit.tokenize("First Test")
      expect(tokens1).to eq(["First", "Test"])

      # Second configuration
      TokenKit.configure do |config|
        config.strategy = :unicode
        config.lowercase = true
      end

      tokens2 = TokenKit.tokenize("Second Test")
      expect(tokens2).to eq(["second", "test"])
    end

    it "handles reset -> configure cycle" do
      # Configure away from defaults
      TokenKit.configure do |config|
        config.strategy = :pattern
        config.regex = /\w+/
        config.lowercase = false
        config.remove_punctuation = true
      end

      # Reset to defaults
      TokenKit.reset
      expect(TokenKit.config.strategy).to eq(:unicode)
      expect(TokenKit.config.lowercase).to eq(true)
      expect(TokenKit.config.remove_punctuation).to eq(false)

      # Configure again
      TokenKit.configure do |config|
        config.strategy = :whitespace
      end

      expect(TokenKit.config.strategy).to eq(:whitespace)
    end
  end

  describe "invalid state transitions" do
    it "rolls back on validation error" do
      # Set initial state
      TokenKit.configure do |config|
        config.strategy = :unicode
        config.lowercase = false
        config.preserve_patterns = [/test/]
      end

      initial_strategy = TokenKit.config.strategy
      initial_lowercase = TokenKit.config.lowercase
      initial_patterns = TokenKit.config.preserve_patterns

      # Attempt invalid configuration
      expect {
        TokenKit.configure do |config|
          config.strategy = :edge_ngram
          config.min_gram = -5  # Invalid!
        end
      }.to raise_error(TokenKit::Error)

      # Verify rollback to previous state
      expect(TokenKit.config.strategy).to eq(initial_strategy)
      expect(TokenKit.config.lowercase).to eq(initial_lowercase)
      expect(TokenKit.config.preserve_patterns).to eq(initial_patterns)
    end

    it "rolls back on Rust-side errors" do
      initial_state = TokenKit.config.strategy

      # Attempt configuration that fails in Rust
      expect {
        TokenKit.configure do |config|
          config.strategy = :pattern
          config.regex = "[invalid("  # Invalid regex
        end
        TokenKit.tokenize("test")  # This triggers the Rust error
      }.to raise_error(StandardError)

      # Should rollback to initial state since configure failed
      expect(TokenKit.config.strategy).to eq(initial_state)
    end

    it "prevents transition to invalid strategy" do
      initial = TokenKit.config.strategy

      expect {
        TokenKit.configure do |config|
          config.strategy = :nonexistent_strategy
        end
      }.to raise_error(TokenKit::Error)

      expect(TokenKit.config.strategy).to eq(initial)
    end
  end

  describe "state consistency" do
    it "maintains consistency between Ruby and Rust state" do
      TokenKit.configure do |config|
        config.strategy = :whitespace
        config.lowercase = false
      end

      # Ruby state
      expect(TokenKit.config.strategy).to eq(:whitespace)
      expect(TokenKit.config.lowercase).to eq(false)

      # Rust state (via config_hash which reflects actual tokenizer state)
      rust_config = TokenKit.config_hash
      expect(rust_config.strategy).to eq(:whitespace)
      expect(rust_config.lowercase).to eq(false)
    end

    it "handles partial configuration updates" do
      TokenKit.configure do |config|
        config.strategy = :edge_ngram
        config.min_gram = 2
        config.max_gram = 5
      end

      # Update only max_gram
      TokenKit.configure do |config|
        config.max_gram = 10
      end

      expect(TokenKit.config.strategy).to eq(:edge_ngram)
      expect(TokenKit.config.min_gram).to eq(2)
      expect(TokenKit.config.max_gram).to eq(10)
    end
  end

  describe "complex state transitions" do
    it "handles rapid strategy switching" do
      strategies = [:unicode, :whitespace, :letter, :lowercase, :sentence]

      10.times do
        strategy = strategies.sample
        TokenKit.configure { |c| c.strategy = strategy }
        tokens = TokenKit.tokenize("Quick test")
        expect(tokens).to be_a(Array)
      end
    end

    it "preserves preserve_patterns across strategy changes" do
      patterns = [/GENE-\d+/, /v\d+\.\d+/]

      TokenKit.configure do |config|
        config.strategy = :unicode
        config.preserve_patterns = patterns
      end

      expect(TokenKit.config.preserve_patterns).to eq(patterns)

      # Change strategy but keep patterns
      TokenKit.configure do |config|
        config.strategy = :whitespace
      end

      expect(TokenKit.config.preserve_patterns).to eq(patterns)

      tokens = TokenKit.tokenize("GENE-123 v2.0 test")
      expect(tokens).to include("GENE-123", "v2.0")
    end

    it "handles strategy-specific parameters correctly" do
      # Set edge_ngram with specific params
      TokenKit.configure do |config|
        config.strategy = :edge_ngram
        config.min_gram = 3
        config.max_gram = 7
      end

      expect(TokenKit.config.min_gram).to eq(3)
      expect(TokenKit.config.max_gram).to eq(7)

      # Switch to non-ngram strategy
      TokenKit.configure do |config|
        config.strategy = :unicode
      end

      # min/max_gram should still be accessible (retained in Config)
      expect(TokenKit.config.min_gram).to eq(3)

      # Switch back to edge_ngram
      TokenKit.configure do |config|
        config.strategy = :edge_ngram
      end

      # Parameters should still be there
      expect(TokenKit.config.min_gram).to eq(3)
      expect(TokenKit.config.max_gram).to eq(7)
    end
  end

  describe "edge cases" do
    it "handles empty configuration block" do
      initial_strategy = TokenKit.config.strategy

      TokenKit.configure do |config|
        # Empty block - no changes
      end

      expect(TokenKit.config.strategy).to eq(initial_strategy)
    end

    it "handles multiple rapid resets" do
      5.times do
        TokenKit.configure { |c| c.strategy = :whitespace }
        TokenKit.reset
        expect(TokenKit.config.strategy).to eq(:unicode)
      end
    end

    it "handles configuration without block" do
      # This should be valid but do nothing
      expect { TokenKit.configure }.not_to raise_error

      # Or it might apply current config to Rust
      tokens = TokenKit.tokenize("test")
      expect(tokens).to be_a(Array)
    end

    it "maintains config integrity with per-call options" do
      TokenKit.configure do |config|
        config.strategy = :unicode
        config.lowercase = true
      end

      # Per-call options shouldn't affect global state
      tokens = TokenKit.tokenize("TEST", strategy: :whitespace, lowercase: false)

      # Global state unchanged
      expect(TokenKit.config.strategy).to eq(:unicode)
      expect(TokenKit.config.lowercase).to eq(true)

      # Next call uses global config
      tokens2 = TokenKit.tokenize("TEST")
      expect(tokens2).to eq(["test"])
    end
  end

  describe "configuration atomicity" do
    it "applies all changes atomically on success" do
      TokenKit.configure do |config|
        config.strategy = :edge_ngram
        config.min_gram = 2
        config.max_gram = 5
        config.lowercase = false
        config.remove_punctuation = true
      end

      # All changes should be applied
      expect(TokenKit.config.strategy).to eq(:edge_ngram)
      expect(TokenKit.config.min_gram).to eq(2)
      expect(TokenKit.config.max_gram).to eq(5)
      expect(TokenKit.config.lowercase).to eq(false)
      expect(TokenKit.config.remove_punctuation).to eq(true)
    end

    it "rolls back all changes on failure" do
      # Set initial state
      TokenKit.configure do |config|
        config.strategy = :unicode
        config.lowercase = false
        config.remove_punctuation = false
        config.preserve_patterns = []
      end

      # Attempt mixed valid/invalid changes
      expect {
        TokenKit.configure do |config|
          config.strategy = :edge_ngram  # Valid
          config.lowercase = true         # Valid
          config.remove_punctuation = true # Valid
          config.min_gram = 5             # Valid
          config.max_gram = 3             # Invalid! (less than min_gram)
        end
      }.to raise_error(TokenKit::Error)

      # ALL changes should be rolled back
      expect(TokenKit.config.strategy).to eq(:unicode)
      expect(TokenKit.config.lowercase).to eq(false)
      expect(TokenKit.config.remove_punctuation).to eq(false)
    end
  end
end