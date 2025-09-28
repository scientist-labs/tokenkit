RSpec.describe TokenKit do
  it "has a version number" do
    expect(TokenKit::VERSION).not_to be_nil
  end

  describe ".tokenize" do
    after { TokenKit.reset }

    context "with default configuration" do
      it "tokenizes simple text" do
        tokens = TokenKit.tokenize("Hello world")
        expect(tokens).to eq(["hello", "world"])
      end

      it "handles unicode text" do
        tokens = TokenKit.tokenize("café résumé")
        expect(tokens).to eq(["café", "résumé"])
      end

      it "handles contractions" do
        tokens = TokenKit.tokenize("can't won't don't")
        expect(tokens).to eq(["can't", "won't", "don't"])
      end
    end

    context "with one-off options" do
      it "tokenizes with lowercase disabled" do
        tokens = TokenKit.tokenize("Hello World", lowercase: false)
        expect(tokens).to eq(["Hello", "World"])
      end

      it "tokenizes with whitespace strategy" do
        tokens = TokenKit.tokenize("can't do it", strategy: :whitespace)
        expect(tokens).to eq(["can't", "do", "it"])
      end

      it "tokenizes with preserve patterns" do
        tokens = TokenKit.tokenize(
          "Anti-CD3 antibody 100ug",
          preserve: [/\d+ug/i]
        )
        expect(tokens).to include("100ug")
        expect(tokens).to include("antibody")
      end
    end
  end

  describe ".configure" do
    after { TokenKit.reset }

    it "configures tokenizer with block" do
      TokenKit.configure do |config|
        config.strategy = :whitespace
        config.lowercase = false
      end

      tokens = TokenKit.tokenize("Hello World")
      expect(tokens).to eq(["Hello", "World"])
    end

    it "preserves configuration across calls" do
      TokenKit.configure do |config|
        config.lowercase = false
      end

      tokens1 = TokenKit.tokenize("Hello")
      tokens2 = TokenKit.tokenize("World")

      expect(tokens1).to eq(["Hello"])
      expect(tokens2).to eq(["World"])
    end

    it "supports preserve_patterns" do
      TokenKit.configure do |config|
        config.preserve_patterns = [/\d+ug/i, /anti-\w+/i]
      end

      tokens = TokenKit.tokenize("Anti-CD3 antibody 100ug dose")
      expect(tokens).to include("100ug")
    end
  end

  describe ".config" do
    after { TokenKit.reset }

    it "returns current configuration" do
      TokenKit.configure do |config|
        config.strategy = :whitespace
        config.lowercase = false
      end

      expect(TokenKit.config.strategy).to eq(:whitespace)
      expect(TokenKit.config.lowercase).to eq(false)
    end
  end

  describe ".config_hash" do
    after { TokenKit.reset }

    it "returns configuration as Configuration object" do
      TokenKit.configure do |config|
        config.strategy = :unicode
        config.lowercase = true
      end

      config = TokenKit.config_hash
      expect(config).to be_a(TokenKit::Configuration)
      expect(config.strategy).to eq(:unicode)
      expect(config.lowercase).to eq(true)
    end
  end

  describe ".reset" do
    it "resets configuration to default" do
      TokenKit.configure do |config|
        config.lowercase = false
      end

      TokenKit.reset

      tokens = TokenKit.tokenize("Hello")
      expect(tokens).to eq(["hello"])
    end
  end
end
