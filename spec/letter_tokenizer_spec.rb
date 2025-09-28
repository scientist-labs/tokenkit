# frozen_string_literal: true

RSpec.describe "Letter Tokenizer" do
  before do
    TokenKit.configure do |config|
      config.strategy = :letter
      config.lowercase = true
    end
  end

  after { TokenKit.reset }

  it "splits on any non-letter character" do
    tokens = TokenKit.tokenize("hello-world")
    expect(tokens).to eq(["hello", "world"])
  end

  it "splits on numbers" do
    tokens = TokenKit.tokenize("test123done")
    expect(tokens).to eq(["test", "done"])
  end

  it "splits on punctuation" do
    tokens = TokenKit.tokenize("hello, world!")
    expect(tokens).to eq(["hello", "world"])
  end

  it "splits on spaces" do
    tokens = TokenKit.tokenize("hello world")
    expect(tokens).to eq(["hello", "world"])
  end

  it "splits on special characters" do
    tokens = TokenKit.tokenize("user@example.com")
    expect(tokens).to eq(["user", "example", "com"])
  end

  it "handles multiple consecutive non-letters" do
    tokens = TokenKit.tokenize("hello---world")
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

  it "preserves unicode letters" do
    tokens = TokenKit.tokenize("café-naïve")
    expect(tokens).to eq(["café", "naïve"])
  end

  it "handles CJK characters" do
    TokenKit.configure do |config|
      config.strategy = :letter
      config.lowercase = false
    end

    tokens = TokenKit.tokenize("日本語123test")
    expect(tokens).to eq(["日本語", "test"])
  end

  context "with lowercase option" do
    it "lowercases the tokens" do
      tokens = TokenKit.tokenize("HELLO-WORLD")
      expect(tokens).to eq(["hello", "world"])
    end
  end

  context "with lowercase disabled" do
    before do
      TokenKit.configure do |config|
        config.strategy = :letter
        config.lowercase = false
      end
    end

    it "preserves original case" do
      tokens = TokenKit.tokenize("HELLO-WORLD")
      expect(tokens).to eq(["HELLO", "WORLD"])
    end
  end

  context "with remove_punctuation option" do
    before do
      TokenKit.configure do |config|
        config.strategy = :letter
        config.lowercase = false
        config.remove_punctuation = true
      end
    end

    it "has no additional effect since punctuation already splits" do
      tokens = TokenKit.tokenize("hello!world?")
      expect(tokens).to eq(["hello", "world"])
    end
  end

  context "simpler than Unicode tokenizer" do
    it "splits contractions" do
      # Unlike Unicode which preserves "can't", Letter splits it
      tokens = TokenKit.tokenize("can't")
      expect(tokens).to eq(["can", "t"])
    end

    it "splits hyphenated words" do
      tokens = TokenKit.tokenize("mother-in-law")
      expect(tokens).to eq(["mother", "in", "law"])
    end
  end

  context "language-agnostic use case" do
    before do
      TokenKit.configure do |config|
        config.strategy = :letter
        config.lowercase = false
      end
    end

    it "handles mixed scripts" do
      # CJK characters are also letters, so they don't split
      tokens = TokenKit.tokenize("Hello世界test")
      expect(tokens).to eq(["Hello世界test"])
    end

    it "splits on non-letter characters between scripts" do
      tokens = TokenKit.tokenize("Hello-世界-test")
      expect(tokens).to eq(["Hello", "世界", "test"])
    end
  end

  context "cleaning noisy text" do
    it "extracts only letter sequences" do
      tokens = TokenKit.tokenize("!!!SALE!!!50%OFF!!!")
      expect(tokens).to eq(["sale", "off"])
    end

    it "handles social media text" do
      tokens = TokenKit.tokenize("#hashtag @mention http://url.com")
      expect(tokens).to eq(["hashtag", "mention", "http", "url", "com"])
    end
  end

  context "per-call options" do
    it "can use letter strategy in one-off call" do
      tokens = TokenKit.tokenize(
        "test123done",
        strategy: :letter,
        lowercase: false
      )
      expect(tokens).to eq(["test", "done"])
    end
  end

  context "emoji handling" do
    it "treats emoji as non-alphabetic characters" do
      tokens = TokenKit.tokenize("hello🔥world", strategy: :letter)
      # Emoji should split the text
      expect(tokens).to eq(["hello", "world"])
    end

    it "handles multiple emoji" do
      tokens = TokenKit.tokenize("test😀😂done", strategy: :letter)
      expect(tokens).to eq(["test", "done"])
    end

    it "handles emoji with text" do
      tokens = TokenKit.tokenize("I❤️Ruby", strategy: :letter, lowercase: false)
      expect(tokens).to eq(["I", "Ruby"])
    end

    it "handles only emoji" do
      tokens = TokenKit.tokenize("🔥🎉🚀", strategy: :letter)
      expect(tokens).to eq([])
    end
  end

end
