RSpec.describe "Whitespace Tokenizer" do
  before do
    TokenKit.configure do |config|
      config.strategy = :whitespace
    end
  end

  after { TokenKit.reset }

  it "splits on whitespace" do
    tokens = TokenKit.tokenize("Hello world test")
    expect(tokens).to eq(["hello", "world", "test"])
  end

  it "handles tabs and newlines" do
    tokens = TokenKit.tokenize("Hello\tworld\ntest")
    expect(tokens).to eq(["hello", "world", "test"])
  end

  it "handles multiple spaces" do
    tokens = TokenKit.tokenize("Hello    world")
    expect(tokens).to eq(["hello", "world"])
  end

  it "preserves punctuation within words" do
    tokens = TokenKit.tokenize("can't won't don't")
    expect(tokens).to eq(["can't", "won't", "don't"])
  end

  it "handles hyphens" do
    tokens = TokenKit.tokenize("anti-CD3 top-notch")
    expect(tokens).to eq(["anti-cd3", "top-notch"])
  end

  context "with preserve_patterns" do
    it "preserves matched patterns while lowercasing others" do
      TokenKit.configure do |config|
        config.strategy = :whitespace
        config.lowercase = true
        config.preserve_patterns = [/BRCA\d+/, /TP53/]
      end

      tokens = TokenKit.tokenize("Patient has BRCA1 and TP53 mutations")
      expect(tokens).to eq(["patient", "has", "BRCA1", "and", "TP53", "mutations"])
    end

    it "preserves measurement patterns" do
      TokenKit.configure do |config|
        config.strategy = :whitespace
        config.lowercase = true
        config.preserve_patterns = [/\d+(ug|mg|ml)/i]
      end

      tokens = TokenKit.tokenize("Dosage 100mg twice 50ug daily")
      expect(tokens).to eq(["dosage", "100mg", "twice", "50ug", "daily"])
    end

    it "preserves email addresses" do
      TokenKit.configure do |config|
        config.strategy = :whitespace
        config.lowercase = true
        config.preserve_patterns = [/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/]
      end

      tokens = TokenKit.tokenize("Contact John.Doe@example.com today")
      expect(tokens).to eq(["contact", "John.Doe@example.com", "today"])
    end

    it "preserves multiple pattern types" do
      TokenKit.configure do |config|
        config.strategy = :whitespace
        config.lowercase = true
        config.preserve_patterns = [
          /anti-CD\d+/i,
          /Ig[GMAE]/,
          /\d+ml/i,
          /[A-Z]{2,}/
        ]
      end

      tokens = TokenKit.tokenize("Anti-CD3 IgG 100ml BRCA treatment")
      expect(tokens).to eq(["Anti-CD3", "IgG", "100ml", "BRCA", "treatment"])
    end

    it "works with remove_punctuation" do
      TokenKit.configure do |config|
        config.strategy = :whitespace
        config.lowercase = true
        config.remove_punctuation = true
        config.preserve_patterns = [/USD\d+/]
      end

      tokens = TokenKit.tokenize("Price: USD50! Amazing!")
      expect(tokens).to eq(["price", "USD50", "amazing"])
    end
  end
end
