RSpec.describe "Grapheme Tokenizer" do
  before do
    TokenKit.configure do |config|
      config.strategy = :grapheme
      config.lowercase = false
    end
  end

  after { TokenKit.reset }

  it "splits text into grapheme clusters" do
    tokens = TokenKit.tokenize("hello")
    expect(tokens).to eq(["h", "e", "l", "l", "o"])
  end

  it "handles emoji as single graphemes" do
    tokens = TokenKit.tokenize("👋🌍")
    expect(tokens).to eq(["👋", "🌍"])
  end

  it "handles family emoji with ZWJ sequences" do
    tokens = TokenKit.tokenize("👨‍👩‍👧‍👦")
    expect(tokens).to include("👨‍👩‍👧‍👦")
    expect(tokens.size).to eq(1)
  end

  it "handles accented characters" do
    tokens = TokenKit.tokenize("café")
    expect(tokens).to eq(["c", "a", "f", "é"])
  end

  it "handles combining characters" do
    text = "e\u0301"
    tokens = TokenKit.tokenize(text)
    expect(tokens.size).to eq(1)
    expect(tokens.first).to eq("e\u0301")
  end

  it "handles regional indicator sequences (flags)" do
    tokens = TokenKit.tokenize("🇺🇸")
    expect(tokens).to include("🇺🇸")
  end

  it "returns empty array for empty string" do
    tokens = TokenKit.tokenize("")
    expect(tokens).to eq([])
  end

  it "handles mixed content" do
    tokens = TokenKit.tokenize("a👋b")
    expect(tokens).to eq(["a", "👋", "b"])
  end

  context "with extended = false" do
    before do
      TokenKit.configure do |config|
        config.strategy = :grapheme
        config.grapheme_extended = false
        config.lowercase = false
      end
    end

    it "uses legacy grapheme boundaries" do
      tokens = TokenKit.tokenize("hello")
      expect(tokens).to eq(["h", "e", "l", "l", "o"])
    end
  end

  context "with lowercase option" do
    before do
      TokenKit.configure do |config|
        config.strategy = :grapheme
        config.lowercase = true
      end
    end

    it "lowercases the graphemes" do
      tokens = TokenKit.tokenize("ABC")
      expect(tokens).to eq(["a", "b", "c"])
    end
  end

  context "with remove_punctuation option" do
    before do
      TokenKit.configure do |config|
        config.strategy = :grapheme
        config.lowercase = false
        config.remove_punctuation = true
      end
    end

    it "removes punctuation graphemes" do
      tokens = TokenKit.tokenize("a,b!")
      expect(tokens).to eq(["a", "b"])
    end
  end
end