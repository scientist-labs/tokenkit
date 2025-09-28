RSpec.describe "Edge N-gram Tokenizer" do
  before do
    TokenKit.configure do |config|
      config.strategy = :edge_ngram
      config.min_gram = 2
      config.max_gram = 10
      config.lowercase = true
    end
  end

  after { TokenKit.reset }

  it "generates edge n-grams from single word" do
    tokens = TokenKit.tokenize("coffee")
    expect(tokens).to eq(["co", "cof", "coff", "coffe", "coffee"])
  end

  it "generates edge n-grams from multiple words" do
    tokens = TokenKit.tokenize("hello world")
    expect(tokens).to eq(["he", "hel", "hell", "hello", "wo", "wor", "worl", "world"])
  end

  it "respects min_gram setting" do
    TokenKit.configure do |config|
      config.strategy = :edge_ngram
      config.min_gram = 3
      config.max_gram = 5
    end

    tokens = TokenKit.tokenize("test")
    expect(tokens).to eq(["tes", "test"])
  end

  it "respects max_gram setting" do
    TokenKit.configure do |config|
      config.strategy = :edge_ngram
      config.min_gram = 2
      config.max_gram = 4
    end

    tokens = TokenKit.tokenize("testing")
    expect(tokens).to eq(["te", "tes", "test"])
  end

  it "handles single character words" do
    TokenKit.configure do |config|
      config.strategy = :edge_ngram
      config.min_gram = 1
      config.max_gram = 3
    end

    tokens = TokenKit.tokenize("a")
    expect(tokens).to eq(["a"])
  end

  it "returns empty array for empty string" do
    tokens = TokenKit.tokenize("")
    expect(tokens).to eq([])
  end

  it "handles unicode characters" do
    TokenKit.configure do |config|
      config.strategy = :edge_ngram
      config.min_gram = 2
      config.max_gram = 4
    end

    tokens = TokenKit.tokenize("café")
    expect(tokens).to eq(["ca", "caf", "café"])
  end

  context "with lowercase option" do
    before do
      TokenKit.configure do |config|
        config.strategy = :edge_ngram
        config.min_gram = 2
        config.max_gram = 6
        config.lowercase = true
      end
    end

    it "lowercases the n-grams" do
      tokens = TokenKit.tokenize("SEARCH")
      expect(tokens).to eq(["se", "sea", "sear", "searc", "search"])
    end
  end

  context "with lowercase disabled" do
    before do
      TokenKit.configure do |config|
        config.strategy = :edge_ngram
        config.min_gram = 2
        config.max_gram = 6
        config.lowercase = false
      end
    end

    it "preserves original case" do
      tokens = TokenKit.tokenize("Search")
      expect(tokens).to eq(["Se", "Sea", "Sear", "Searc", "Search"])
    end
  end

  context "with remove_punctuation option" do
    before do
      TokenKit.configure do |config|
        config.strategy = :edge_ngram
        config.min_gram = 2
        config.max_gram = 4
        config.lowercase = false
        config.remove_punctuation = true
      end
    end

    it "removes punctuation before generating n-grams" do
      tokens = TokenKit.tokenize("hello!")
      expect(tokens).to eq(["he", "hel", "hell"])
    end
  end

  context "autocomplete use case" do
    it "generates prefixes for search-as-you-type" do
      TokenKit.configure do |config|
        config.strategy = :edge_ngram
        config.min_gram = 2
        config.max_gram = 15
        config.lowercase = true
      end

      tokens = TokenKit.tokenize("laptop")
      expect(tokens).to include("la", "lap", "lapt", "lapto", "laptop")
    end
  end
end