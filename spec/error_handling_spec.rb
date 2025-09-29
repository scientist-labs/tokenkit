# frozen_string_literal: true

RSpec.describe "Error Handling" do
  after { TokenKit.reset }

  describe "invalid regex patterns" do
    it "handles invalid pattern regex gracefully" do
      expect {
        TokenKit.configure do |config|
          config.strategy = :pattern
          config.regex = "[invalid("
        end
        TokenKit.tokenize("test")
      }.to raise_error(StandardError, /Invalid regex pattern/)
    end

    it "handles invalid preserve_patterns gracefully" do
      # Note: Currently filters out invalid patterns silently
      # This test documents current behavior - should we change it?
      expect {
        TokenKit.configure do |config|
          config.preserve_patterns = [/valid/, "[invalid("]
        end
      }.not_to raise_error

      # Should still tokenize with valid patterns only
      tokens = TokenKit.tokenize("test valid text")
      expect(tokens).to be_a(Array)
    end
  end

  describe "invalid configuration values" do
    it "handles negative min_gram for edge_ngram" do
      expect {
        TokenKit.configure do |config|
          config.strategy = :edge_ngram
          config.min_gram = -1
          config.max_gram = 5
        end
      }.to raise_error(TokenKit::Error, /min_gram must be positive/)
    end

    it "handles min_gram > max_gram" do
      expect {
        TokenKit.configure do |config|
          config.strategy = :edge_ngram
          config.min_gram = 10
          config.max_gram = 5
        end
      }.to raise_error(TokenKit::Error, /max_gram .* must be >= min_gram/)
    end

    it "raises error for empty delimiter with path_hierarchy" do
      expect {
        TokenKit.configure do |config|
          config.strategy = :path_hierarchy
          config.delimiter = ""
        end
      }.to raise_error(TokenKit::Error, /Path hierarchy requires a delimiter/)
    end
  end

  describe "edge cases" do
    it "handles empty text" do
      tokens = TokenKit.tokenize("")
      expect(tokens).to eq([])
    end

    it "handles nil text" do
      expect { TokenKit.tokenize(nil) }.to raise_error(TypeError)
    end

    it "handles very long text without crashing" do
      long_text = "word " * 100_000
      tokens = TokenKit.tokenize(long_text)
      expect(tokens.size).to be > 0
    end

    it "handles text with only whitespace" do
      tokens = TokenKit.tokenize("   \n\t  ")
      expect(tokens).to eq([])
    end

    it "handles text with special Unicode characters" do
      tokens = TokenKit.tokenize("test\u0000null\uFFFDreplacement")
      expect(tokens).to be_a(Array)
    end
  end

  describe "configuration state errors" do
    it "handles tokenization before configuration" do
      TokenKit.reset
      # Should use defaults
      tokens = TokenKit.tokenize("test text")
      expect(tokens).to eq(["test", "text"])
    end

    it "handles double configuration" do
      TokenKit.configure do |config|
        config.strategy = :whitespace
      end

      TokenKit.configure do |config|
        config.strategy = :unicode
      end

      # Should use latest config
      expect(TokenKit.config.strategy).to eq(:unicode)
    end

    it "preserves config after error" do
      TokenKit.configure do |config|
        config.strategy = :whitespace
        config.lowercase = false
      end

      # Try invalid pattern strategy
      expect {
        TokenKit.configure do |config|
          config.strategy = :pattern
          config.regex = "[invalid("
        end
        TokenKit.tokenize("test")
      }.to raise_error(StandardError)

      # Config should still be whitespace
      expect(TokenKit.config.strategy).to eq(:whitespace)
      expect(TokenKit.config.lowercase).to eq(false)
    end
  end
end