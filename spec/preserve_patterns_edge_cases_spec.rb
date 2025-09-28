RSpec.describe "Pattern Preservation Edge Cases" do
  after { TokenKit.reset }

  context "adjacent non-overlapping matches" do
    before do
      TokenKit.configure do |config|
        config.strategy = :unicode
        config.preserve_patterns = [/[A-Z][A-Z0-9]+/]
      end
    end

    it "preserves multiple adjacent gene names" do
      tokens = TokenKit.tokenize("BRCA1 TP53 EGFR mutations")
      expect(tokens).to include("BRCA1", "TP53", "EGFR", "mutations")
    end

    it "preserves patterns at start and end of text" do
      tokens = TokenKit.tokenize("BRCA1 mutation TP53")
      expect(tokens).to eq(["BRCA1", "mutation", "TP53"])
    end
  end

  context "patterns at document boundaries" do
    before do
      TokenKit.configure do |config|
        config.strategy = :unicode
        config.preserve_patterns = [/\d+mg/i]
      end
    end

    it "preserves pattern at start of text" do
      tokens = TokenKit.tokenize("100mg daily dose")
      expect(tokens).to eq(["100mg", "daily", "dose"])
    end

    it "preserves pattern at end of text" do
      tokens = TokenKit.tokenize("take 100mg")
      expect(tokens).to eq(["take", "100mg"])
    end

    it "preserves pattern as only token" do
      tokens = TokenKit.tokenize("100mg")
      expect(tokens).to eq(["100mg"])
    end
  end

  context "unicode in patterns and text" do
    before do
      TokenKit.configure do |config|
        config.strategy = :unicode
        config.preserve_patterns = [/café|naïve/i]
      end
    end

    it "preserves unicode patterns" do
      tokens = TokenKit.tokenize("the café serves naïve customers")
      expect(tokens).to include("café", "naïve", "the", "serves", "customers")
    end
  end

  context "whitespace normalization around patterns" do
    before do
      TokenKit.configure do |config|
        config.strategy = :unicode
        config.preserve_patterns = [/\d+mg/i]
      end
    end

    it "handles multiple spaces around patterns" do
      tokens = TokenKit.tokenize("take   100mg   daily")
      expect(tokens).to eq(["take", "100mg", "daily"])
    end

    it "handles tabs and newlines around patterns" do
      tokens = TokenKit.tokenize("take\t100mg\ndaily")
      expect(tokens).to eq(["take", "100mg", "daily"])
    end
  end

  context "case-insensitive patterns with mixed case" do
    before do
      TokenKit.configure do |config|
        config.strategy = :unicode
        config.preserve_patterns = [/anti-cd\d+/i]
      end
    end

    it "preserves all case variations" do
      tokens = TokenKit.tokenize("anti-cd3 Anti-CD3 ANTI-CD3")
      expect(tokens).to eq(["anti-cd3", "Anti-CD3", "ANTI-CD3"])
    end
  end

  context "patterns with punctuation" do
    before do
      TokenKit.configure do |config|
        config.strategy = :unicode
        config.preserve_patterns = [/\$\d+(\.\d{2})?/]
        config.remove_punctuation = false
      end
    end

    it "preserves monetary amounts" do
      tokens = TokenKit.tokenize("cost is $99.99 per item")
      expect(tokens).to include("$99.99", "cost", "is", "per", "item")
    end

    it "preserves patterns with dollar sign" do
      tokens = TokenKit.tokenize("$100 and $50")
      expect(tokens).to include("$100", "$50", "and")
    end
  end

  context "empty or all-space text" do
    before do
      TokenKit.configure do |config|
        config.strategy = :unicode
        config.preserve_patterns = [/\d+mg/i]
      end
    end

    it "handles empty string" do
      tokens = TokenKit.tokenize("")
      expect(tokens).to eq([])
    end

    it "handles whitespace-only string" do
      tokens = TokenKit.tokenize("   \t\n   ")
      expect(tokens).to eq([])
    end
  end

  context "very long pattern matches" do
    before do
      TokenKit.configure do |config|
        config.strategy = :unicode
        config.preserve_patterns = [/[A-Z0-9]{10,}/]
      end
    end

    it "preserves long alphanumeric sequences" do
      long_id = "ABC123XYZ789DEFGHIJ"
      tokens = TokenKit.tokenize("id #{long_id} found")
      expect(tokens).to include(long_id, "id", "found")
    end
  end

  context "pattern preservation with remove_punctuation" do
    before do
      TokenKit.configure do |config|
        config.strategy = :unicode
        config.preserve_patterns = [/anti-cd\d+/i]
        config.remove_punctuation = true
      end
    end

    it "preserves hyphens in matched patterns but removes from other tokens" do
      tokens = TokenKit.tokenize("Anti-CD3 is a co-stimulatory antibody")
      expect(tokens).to include("Anti-CD3")
      expect(tokens).to include("costimulatory")
    end
  end
end
