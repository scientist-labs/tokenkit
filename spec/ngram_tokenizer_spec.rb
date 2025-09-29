# frozen_string_literal: true

RSpec.describe "N-gram Tokenizer" do
  before do
    TokenKit.configure do |config|
      config.strategy = :ngram
      config.min_gram = 2
      config.max_gram = 3
      config.lowercase = true
    end
  end

  after { TokenKit.reset }

  it "generates n-grams from single word" do
    tokens = TokenKit.tokenize("quick")
    expect(tokens).to contain_exactly("qu", "ui", "ic", "ck", "qui", "uic", "ick")
  end

  it "generates n-grams from multiple words" do
    tokens = TokenKit.tokenize("hi there")
    expect(tokens).to contain_exactly("hi", "th", "he", "er", "re", "the", "her", "ere")
  end

  it "respects min_gram setting" do
    TokenKit.configure do |config|
      config.strategy = :ngram
      config.min_gram = 3
      config.max_gram = 4
      config.lowercase = false
    end

    tokens = TokenKit.tokenize("test")
    expect(tokens).to contain_exactly("tes", "est", "test")
  end

  it "respects max_gram setting" do
    TokenKit.configure do |config|
      config.strategy = :ngram
      config.min_gram = 2
      config.max_gram = 2
      config.lowercase = false
    end

    tokens = TokenKit.tokenize("hello")
    expect(tokens).to contain_exactly("he", "el", "ll", "lo")
  end

  it "handles single character words with min_gram > 1" do
    tokens = TokenKit.tokenize("a")
    expect(tokens).to eq([])
  end

  it "returns empty array for empty string" do
    tokens = TokenKit.tokenize("")
    expect(tokens).to eq([])
  end

  it "handles unicode characters" do
    tokens = TokenKit.tokenize("café")
    expect(tokens).to include("ca", "af", "fé", "caf", "afé")
  end

  context "with lowercase option" do
    it "lowercases the n-grams" do
      tokens = TokenKit.tokenize("TEST")
      expect(tokens).to include("te", "es", "st", "tes", "est")
    end
  end

  context "with lowercase disabled" do
    before do
      TokenKit.configure do |config|
        config.strategy = :ngram
        config.min_gram = 2
        config.max_gram = 3
        config.lowercase = false
      end
    end

    it "preserves original case" do
      tokens = TokenKit.tokenize("TEST")
      expect(tokens).to include("TE", "ES", "ST", "TES", "EST")
    end
  end

  context "with remove_punctuation option" do
    before do
      TokenKit.configure do |config|
        config.strategy = :ngram
        config.min_gram = 2
        config.max_gram = 3
        config.lowercase = false
        config.remove_punctuation = true
      end
    end

    it "removes punctuation before generating n-grams" do
      tokens = TokenKit.tokenize("hello!")
      expect(tokens).to contain_exactly("he", "el", "ll", "lo", "hel", "ell", "llo")
    end
  end

  context "fuzzy matching use case" do
    before do
      TokenKit.configure do |config|
        config.strategy = :ngram
        config.min_gram = 2
        config.max_gram = 4
        config.lowercase = true
      end
    end

    it "generates n-grams for fuzzy search" do
      tokens = TokenKit.tokenize("search")
      # Should match queries like "earch", "searc", "arch", etc.
      expect(tokens).to include("se", "ea", "ar", "rc", "ch")
      expect(tokens).to include("sea", "ear", "arc", "rch")
      expect(tokens).to include("sear", "earc", "arch")
    end
  end

  context "misspelling tolerance use case" do
    it "handles partial matches for misspellings" do
      # Index time: generate n-grams for "search"
      tokens = TokenKit.tokenize("search")

      # Query time: user types "serch" (missing 'a')
      # N-grams of "serch" would overlap significantly with "search"
      query_tokens = TokenKit.tokenize("serch")

      # Significant overlap between the two sets
      overlap = (tokens & query_tokens).count
      expect(overlap).to be > 0
    end
  end

  context "input validation" do
    it "handles min_gram = 0 by treating it as 1" do
      tokens = TokenKit.tokenize("test", strategy: :ngram, min_gram: 0, max_gram: 2)
      # Should use min_gram = 1 instead
      expect(tokens).to eq(["t", "e", "s", "t", "te", "es", "st"])
    end

    it "handles min_gram > max_gram by adjusting max_gram" do
      tokens = TokenKit.tokenize("test", strategy: :ngram, min_gram: 3, max_gram: 1)
      # Should adjust max_gram to match min_gram
      expect(tokens).to eq(["tes", "est"])
    end

    it "handles both invalid parameters" do
      tokens = TokenKit.tokenize("test", strategy: :ngram, min_gram: 0, max_gram: 0)
      # Should use min_gram = 1, max_gram = 1
      expect(tokens).to eq(["t", "e", "s", "t"])
    end

    it "handles very large min_gram values" do
      tokens = TokenKit.tokenize("test", strategy: :ngram, min_gram: 10, max_gram: 15)
      # min_gram > word length, should return empty
      expect(tokens).to eq([])
    end

    it "works correctly with valid parameters" do
      tokens = TokenKit.tokenize("test", strategy: :ngram, min_gram: 2, max_gram: 3)
      expect(tokens).to eq(["te", "es", "st", "tes", "est"])
    end

    it "handles min_gram = max_gram" do
      tokens = TokenKit.tokenize("test", strategy: :ngram, min_gram: 2, max_gram: 2)
      expect(tokens).to eq(["te", "es", "st"])
    end
  end

  context "performance with long words" do
    it "handles very long words efficiently" do
      long_word = "a" * 100
      tokens = TokenKit.tokenize(long_word, strategy: :ngram, min_gram: 2, max_gram: 3)
      # Should generate 99 bigrams + 98 trigrams = 197 n-grams
      expect(tokens.size).to eq(197)
      expect(tokens.first).to eq("aa")
      expect(tokens.last).to eq("aaa")
    end
  end

end
