# frozen_string_literal: true

RSpec.describe "Regex Flags Support" do
  after { TokenKit.reset }

  describe "case-insensitive flag (i)" do
    it "preserves case-insensitive patterns" do
      TokenKit.configure do |config|
        config.preserve_patterns = [/GENE-\d+/i]
        config.lowercase = true
      end

      tokens = TokenKit.tokenize("The gene-123 and GENE-456 were identified")
      expect(tokens).to include("gene-123", "GENE-456")
    end

    it "works with pattern strategy" do
      TokenKit.configure do |config|
        config.strategy = :pattern
        config.regex = /[A-Z]+/i
        config.lowercase = false
      end

      tokens = TokenKit.tokenize("ABC def GHI")
      expect(tokens).to contain_exactly("ABC", "def", "GHI")
    end
  end

  describe "multiline flag (m)" do
    it "passes multiline flag to Rust regex engine" do
      TokenKit.configure do |config|
        config.strategy = :pattern
        config.regex = /test./m
      end

      tokens = TokenKit.tokenize("test1 test2 test3")
      expect(tokens).to contain_exactly("test1", "test2", "test3")
    end

    it "converts multiline flag in preserve patterns" do
      TokenKit.configure do |config|
        config.preserve_patterns = [/CODE-\d+/m]
      end

      tokens = TokenKit.tokenize("Found CODE-123 in file")
      expect(tokens).to include("CODE-123")
    end
  end

  describe "extended flag (x)" do
    it "allows whitespace and comments in patterns" do
      pattern = /
        GENE-     # Gene prefix
        \d{3,5}   # 3-5 digits
      /x

      TokenKit.configure do |config|
        config.preserve_patterns = [pattern]
      end

      tokens = TokenKit.tokenize("Found GENE-12345 in sequence")
      expect(tokens).to include("GENE-12345")
    end

    it "works with pattern strategy" do
      pattern = /
        \w+       # word characters
        @         # at sign
        \w+       # domain name
        \.        # dot
        \w+       # tld
      /x

      TokenKit.configure do |config|
        config.strategy = :pattern
        config.regex = pattern
      end

      tokens = TokenKit.tokenize("Contact user@example.com for info")
      expect(tokens).to include("user@example.com")
    end
  end

  describe "combined flags" do
    it "supports case-insensitive and multiline together" do
      TokenKit.configure do |config|
        config.preserve_patterns = [/CODE-\d+/im]
        config.lowercase = true
      end

      tokens = TokenKit.tokenize("Found code-123 here")
      expect(tokens).to include("code-123")
    end

    it "supports all three flags together" do
      pattern = /
        GENE-     # prefix
        \d+       # digits
      /imx

      TokenKit.configure do |config|
        config.preserve_patterns = [pattern]
        config.lowercase = true
      end

      tokens = TokenKit.tokenize("Found gene-123 in sample")
      expect(tokens).to include("gene-123")
    end
  end

  describe "flag conversion to Rust format" do
    it "converts Ruby IGNORECASE to Rust (?i)" do
      TokenKit.configure do |config|
        config.preserve_patterns = [/test/i]
      end

      tokens = TokenKit.tokenize("Test TEST test")
      expect(tokens).to include("Test", "TEST", "test")
    end

    it "converts Ruby MULTILINE to Rust (?m)" do
      TokenKit.configure do |config|
        config.preserve_patterns = [/a.b/m]
      end

      tokens = TokenKit.tokenize("aXb test")
      expect(tokens).to include("aXb")
    end

    it "converts Ruby EXTENDED to Rust (?x)" do
      TokenKit.configure do |config|
        config.preserve_patterns = [/a b c/x]
      end

      tokens = TokenKit.tokenize("abc test")
      expect(tokens).to include("abc")
    end

    it "converts combined flags to Rust (?imx)" do
      TokenKit.configure do |config|
        config.preserve_patterns = [/test/imx]
      end

      tokens = TokenKit.tokenize("TEST")
      expect(tokens).to include("TEST")
    end
  end

  describe "one-off tokenize with regex flags" do
    it "respects case-insensitive flag in one-off call" do
      tokens = TokenKit.tokenize(
        "ABC def GHI",
        strategy: :pattern,
        regex: /[a-z]+/i,
        lowercase: false
      )
      expect(tokens).to contain_exactly("ABC", "def", "GHI")
    end

    it "respects multiline flag in one-off preserve pattern" do
      tokens = TokenKit.tokenize(
        "Found CODE-456 here",
        preserve: [/CODE-\d+/m]
      )
      expect(tokens).to include("CODE-456")
    end
  end

  describe "edge cases" do
    it "handles pattern with no flags" do
      TokenKit.configure do |config|
        config.preserve_patterns = [/GENE-\d+/]
      end

      tokens = TokenKit.tokenize("Found GENE-123 here")
      expect(tokens).to include("GENE-123")
    end

    it "handles empty preserve patterns array" do
      TokenKit.configure do |config|
        config.preserve_patterns = []
      end

      tokens = TokenKit.tokenize("test text")
      expect(tokens).to eq(["test", "text"])
    end

    it "handles multiple patterns with different flags" do
      TokenKit.configure do |config|
        config.preserve_patterns = [
          /GENE-\d+/i,
          /PROTEIN-\d+/,
          /RNA-\d+/m
        ]
      end

      tokens = TokenKit.tokenize("gene-1 PROTEIN-2 rna-3")
      expect(tokens).to include("gene-1", "PROTEIN-2")
    end
  end
end
