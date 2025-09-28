RSpec.describe "Keyword Tokenizer" do
  before do
    TokenKit.configure do |config|
      config.strategy = :keyword
      config.lowercase = false
    end
  end

  after { TokenKit.reset }

  it "treats entire input as single token" do
    tokens = TokenKit.tokenize("hello world")
    expect(tokens).to eq(["hello world"])
  end

  it "trims whitespace from input" do
    tokens = TokenKit.tokenize("  product-sku-123  ")
    expect(tokens).to eq(["product-sku-123"])
  end

  it "preserves internal whitespace" do
    tokens = TokenKit.tokenize("hello   world   test")
    expect(tokens).to eq(["hello   world   test"])
  end

  it "returns empty array for empty string" do
    tokens = TokenKit.tokenize("")
    expect(tokens).to eq([])
  end

  it "returns empty array for whitespace-only string" do
    tokens = TokenKit.tokenize("   ")
    expect(tokens).to eq([])
  end

  it "preserves special characters" do
    tokens = TokenKit.tokenize("SKU-12345-XYZ")
    expect(tokens).to eq(["SKU-12345-XYZ"])
  end

  it "preserves punctuation" do
    tokens = TokenKit.tokenize("user@example.com")
    expect(tokens).to eq(["user@example.com"])
  end

  it "handles unicode characters" do
    tokens = TokenKit.tokenize("café-résumé")
    expect(tokens).to eq(["café-résumé"])
  end

  context "with lowercase option" do
    before do
      TokenKit.configure do |config|
        config.strategy = :keyword
        config.lowercase = true
      end
    end

    it "lowercases the entire token" do
      tokens = TokenKit.tokenize("PRODUCT-SKU-123")
      expect(tokens).to eq(["product-sku-123"])
    end

    it "lowercases unicode characters" do
      tokens = TokenKit.tokenize("CAFÉ")
      expect(tokens).to eq(["café"])
    end
  end

  context "with remove_punctuation option" do
    before do
      TokenKit.configure do |config|
        config.strategy = :keyword
        config.lowercase = false
        config.remove_punctuation = true
      end
    end

    it "removes punctuation from the token" do
      tokens = TokenKit.tokenize("SKU-12345-XYZ!")
      expect(tokens).to eq(["SKU12345XYZ"])
    end

    it "returns empty array if token becomes empty after removing punctuation" do
      tokens = TokenKit.tokenize("!!!")
      expect(tokens).to eq([])
    end
  end

  context "use cases" do
    it "handles product SKUs" do
      tokens = TokenKit.tokenize("PROD-2024-ABC-001")
      expect(tokens).to eq(["PROD-2024-ABC-001"])
    end

    it "handles IDs" do
      tokens = TokenKit.tokenize("UUID-123e4567-e89b-12d3")
      expect(tokens).to eq(["UUID-123e4567-e89b-12d3"])
    end

    it "handles category names" do
      tokens = TokenKit.tokenize("Electronics & Computers")
      expect(tokens).to eq(["Electronics & Computers"])
    end
  end
end