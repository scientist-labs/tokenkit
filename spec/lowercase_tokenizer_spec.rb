# frozen_string_literal: true

RSpec.describe "Lowercase Tokenizer" do
  before do
    TokenKit.configure do |config|
      config.strategy = :lowercase
    end
  end

  after { TokenKit.reset }

  it "splits on non-letters and lowercases" do
    tokens = TokenKit.tokenize("HELLO-WORLD")
    expect(tokens).to eq(["hello", "world"])
  end

  it "always lowercases regardless of config" do
    expect {
      TokenKit.configure do |config|
        config.strategy = :lowercase
        config.lowercase = false  # This should be ignored
      end
    }.to output(/Warning: The :lowercase strategy always lowercases text/).to_stderr

    tokens = TokenKit.tokenize("TEST")
    expect(tokens).to eq(["test"])
  end

  it "splits on numbers" do
    tokens = TokenKit.tokenize("TEST123DONE")
    expect(tokens).to eq(["test", "done"])
  end

  it "splits on punctuation" do
    tokens = TokenKit.tokenize("HELLO, WORLD!")
    expect(tokens).to eq(["hello", "world"])
  end

  it "splits on spaces" do
    tokens = TokenKit.tokenize("HELLO WORLD")
    expect(tokens).to eq(["hello", "world"])
  end

  it "splits on special characters" do
    tokens = TokenKit.tokenize("USER@EXAMPLE.COM")
    expect(tokens).to eq(["user", "example", "com"])
  end

  it "handles multiple consecutive non-letters" do
    tokens = TokenKit.tokenize("HELLO---WORLD")
    expect(tokens).to eq(["hello", "world"])
  end

  it "returns empty array for empty string" do
    tokens = TokenKit.tokenize("")
    expect(tokens).to eq([])
  end

  it "returns empty array for string with no letters" do
    tokens = TokenKit.tokenize("123!@#")
    expect(tokens).to eq([])
  end

  it "lowercases unicode letters" do
    tokens = TokenKit.tokenize("CAFÉ-NAÏVE")
    expect(tokens).to eq(["café", "naïve"])
  end

  context "multi-character lowercasing" do
    it "handles Turkish İ (capital I with dot above)" do
      # Turkish İ (U+0130) lowercases to i (U+0069) + combining dot (U+0307)
      tokens = TokenKit.tokenize("İSTANBUL")
      expect(tokens).to eq(["i̇stanbul"])
      expect(tokens.first.chars.count).to eq(9) # i + combining + stanbul = 9 chars
    end

    it "handles multi-char lowercasing mixed with regular characters" do
      # İ in the middle of a word
      tokens = TokenKit.tokenize("TESTİNG")
      expect(tokens).to eq(["testi̇ng"])
      expect(tokens.first.chars.count).to eq(8) # t-e-s-t-i̇-n-g (i̇ is 2 chars)
    end

    it "handles multiple words with multi-char lowercasing" do
      tokens = TokenKit.tokenize("İSTANBUL İZMİR")
      expect(tokens).to eq(["i̇stanbul", "i̇zmi̇r"])
      expect(tokens[0].chars.count).to eq(9) # i̇-s-t-a-n-b-u-l
      expect(tokens[1].chars.count).to eq(7) # i̇-z-m-i̇-r (two İ characters)
    end

    it "handles multiple İ characters in one word" do
      tokens = TokenKit.tokenize("İİ")
      expect(tokens).to eq(["i̇i̇"])
      expect(tokens.first.chars.count).to eq(4) # Two i̇ sequences
    end

    it "handles İ at different positions" do
      # Start, middle, end
      tokens = TokenKit.tokenize("İTALİA")
      expect(tokens).to eq(["i̇tali̇a"])
      expect(tokens.first.chars.count).to eq(8) # i̇-t-a-l-i̇-a
    end
  end

  it "handles mixed case input" do
    tokens = TokenKit.tokenize("MiXeD-CaSe")
    expect(tokens).to eq(["mixed", "case"])
  end

  it "handles CJK characters" do
    tokens = TokenKit.tokenize("日本語123TEST")
    expect(tokens).to eq(["日本語", "test"])
  end

  context "with remove_punctuation option" do
    before do
      TokenKit.configure do |config|
        config.strategy = :lowercase
        config.remove_punctuation = true
      end
    end

    it "has no additional effect since punctuation already splits" do
      tokens = TokenKit.tokenize("HELLO!WORLD?")
      expect(tokens).to eq(["hello", "world"])
    end
  end

  context "efficiency over letter + lowercase" do
    it "performs normalization in single pass" do
      # Lowercase tokenizer is more efficient than:
      # 1. Letter tokenizer
      # 2. + lowercase filter
      # Because it does both in one pass
      tokens = TokenKit.tokenize("HELLO123WORLD")
      expect(tokens).to eq(["hello", "world"])
    end
  end

  context "case-insensitive search indexing" do
    it "normalizes for case-insensitive matching" do
      # Index time
      doc_tokens = TokenKit.tokenize("User-Agent: Mozilla/5.0")

      # Query time - user searches with different case
      query_tokens = TokenKit.tokenize("user agent mozilla")

      # Perfect match after normalization
      expect(doc_tokens).to eq(["user", "agent", "mozilla"])
      expect(query_tokens).to eq(["user", "agent", "mozilla"])
    end
  end

  context "product codes and SKUs" do
    it "normalizes product identifiers" do
      tokens = TokenKit.tokenize("SKU-ABC-123")
      expect(tokens).to eq(["sku", "abc"])
    end
  end

  context "cleaning social media text" do
    it "extracts and normalizes words" do
      tokens = TokenKit.tokenize("#TRENDING @USER HTTP://URL.COM")
      expect(tokens).to eq(["trending", "user", "http", "url", "com"])
    end
  end

  context "per-call options" do
    it "can use lowercase strategy in one-off call" do
      tokens = TokenKit.tokenize(
        "TEST123DONE",
        strategy: :lowercase
      )
      expect(tokens).to eq(["test", "done"])
    end

    it "ignores lowercase option when using lowercase strategy" do
      expect {
        tokens = TokenKit.tokenize(
          "TEST",
          strategy: :lowercase,
          lowercase: false  # Should be ignored
        )
        expect(tokens).to eq(["test"])
      }.to output(/Warning: The :lowercase strategy always lowercases text/).to_stderr
    end
  end

  context "comparison with letter tokenizer" do
    it "behaves like letter tokenizer but always lowercase" do
      letter_tokens = TokenKit.tokenize("HELLO-WORLD", strategy: :letter, lowercase: true)
      lowercase_tokens = TokenKit.tokenize("HELLO-WORLD", strategy: :lowercase)

      expect(lowercase_tokens).to eq(letter_tokens)
    end
  end

  context "emoji handling" do
    it "treats emoji as non-alphabetic characters and lowercases" do
      tokens = TokenKit.tokenize("HELLO🔥WORLD", strategy: :lowercase)
      # Emoji should split the text, and text should be lowercased
      expect(tokens).to eq(["hello", "world"])
    end

    it "handles multiple emoji with mixed case" do
      tokens = TokenKit.tokenize("TEST😀😂Done", strategy: :lowercase)
      expect(tokens).to eq(["test", "done"])
    end

    it "handles emoji with text" do
      tokens = TokenKit.tokenize("I❤️RUBY", strategy: :lowercase)
      expect(tokens).to eq(["i", "ruby"])
    end

    it "handles only emoji" do
      tokens = TokenKit.tokenize("🔥🎉🚀", strategy: :lowercase)
      expect(tokens).to eq([])
    end
  end

end
