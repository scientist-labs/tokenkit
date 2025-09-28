# frozen_string_literal: true

RSpec.describe "Character Group Tokenizer" do
  after { TokenKit.reset }

  context "with default whitespace splitting" do
    before do
      TokenKit.configure do |config|
        config.strategy = :char_group
        config.split_on_chars = " \t\n"
        config.lowercase = true
      end
    end

    it "splits on spaces" do
      tokens = TokenKit.tokenize("hello world")
      expect(tokens).to eq(["hello", "world"])
    end

    it "splits on tabs" do
      tokens = TokenKit.tokenize("hello\tworld")
      expect(tokens).to eq(["hello", "world"])
    end

    it "splits on newlines" do
      tokens = TokenKit.tokenize("hello\nworld")
      expect(tokens).to eq(["hello", "world"])
    end

    it "handles multiple consecutive split characters" do
      tokens = TokenKit.tokenize("hello  \t\n  world")
      expect(tokens).to eq(["hello", "world"])
    end
  end

  context "with comma and semicolon separators" do
    before do
      TokenKit.configure do |config|
        config.strategy = :char_group
        config.split_on_chars = ",;"
        config.lowercase = false
      end
    end

    it "splits on commas" do
      tokens = TokenKit.tokenize("apple,banana,cherry")
      expect(tokens).to eq(["apple", "banana", "cherry"])
    end

    it "splits on semicolons" do
      tokens = TokenKit.tokenize("one;two;three")
      expect(tokens).to eq(["one", "two", "three"])
    end

    it "splits on both commas and semicolons" do
      tokens = TokenKit.tokenize("a,b;c,d")
      expect(tokens).to eq(["a", "b", "c", "d"])
    end

    it "preserves spaces within tokens" do
      tokens = TokenKit.tokenize("first item,second item")
      expect(tokens).to eq(["first item", "second item"])
    end
  end

  context "with pipe separator" do
    before do
      TokenKit.configure do |config|
        config.strategy = :char_group
        config.split_on_chars = "|"
        config.lowercase = false
      end
    end

    it "splits on pipes" do
      tokens = TokenKit.tokenize("field1|field2|field3")
      expect(tokens).to eq(["field1", "field2", "field3"])
    end
  end

  context "with custom character set" do
    before do
      TokenKit.configure do |config|
        config.strategy = :char_group
        config.split_on_chars = ":-/"
        config.lowercase = false
      end
    end

    it "splits on hyphens, colons, and slashes" do
      tokens = TokenKit.tokenize("date:2024-01-15/path")
      expect(tokens).to eq(["date", "2024", "01", "15", "path"])
    end
  end

  it "returns empty array for empty string" do
    TokenKit.configure do |config|
      config.strategy = :char_group
      config.split_on_chars = ","
    end

    tokens = TokenKit.tokenize("")
    expect(tokens).to eq([])
  end

  it "returns single token when no split characters present" do
    TokenKit.configure do |config|
      config.strategy = :char_group
      config.split_on_chars = ","
      config.lowercase = false
    end

    tokens = TokenKit.tokenize("nosplitcharacters")
    expect(tokens).to eq(["nosplitcharacters"])
  end

  context "with lowercase option" do
    before do
      TokenKit.configure do |config|
        config.strategy = :char_group
        config.split_on_chars = ","
        config.lowercase = true
      end
    end

    it "lowercases the tokens" do
      tokens = TokenKit.tokenize("APPLE,BANANA")
      expect(tokens).to eq(["apple", "banana"])
    end
  end

  context "with remove_punctuation option" do
    before do
      TokenKit.configure do |config|
        config.strategy = :char_group
        config.split_on_chars = ","
        config.lowercase = false
        config.remove_punctuation = true
      end
    end

    it "removes punctuation from tokens" do
      tokens = TokenKit.tokenize("apple!,banana?,cherry.")
      expect(tokens).to eq(["apple", "banana", "cherry"])
    end
  end

  context "CSV parsing use case" do
    before do
      TokenKit.configure do |config|
        config.strategy = :char_group
        config.split_on_chars = ","
        config.lowercase = false
      end
    end

    it "parses comma-separated values" do
      tokens = TokenKit.tokenize("John Doe,30,Software Engineer")
      expect(tokens).to eq(["John Doe", "30", "Software Engineer"])
    end
  end

  context "log parsing use case" do
    before do
      TokenKit.configure do |config|
        config.strategy = :char_group
        config.split_on_chars = " []"
        config.lowercase = false
      end
    end

    it "splits on spaces and brackets" do
      tokens = TokenKit.tokenize("[INFO] User logged in successfully")
      expect(tokens).to eq(["INFO", "User", "logged", "in", "successfully"])
    end
  end

  context "per-call options" do
    it "can override split_on_chars in one-off call" do
      tokens = TokenKit.tokenize(
        "a:b:c",
        strategy: :char_group,
        split_on_chars: ":"
      )
      expect(tokens).to eq(["a", "b", "c"])
    end
  end

  context "edge cases" do
    it "handles empty split_on_chars by not splitting" do
      tokens = TokenKit.tokenize(
        "hello world",
        strategy: :char_group,
        split_on_chars: ""
      )
      expect(tokens).to eq(["hello world"])
    end

    it "handles split_on_chars with only one character" do
      tokens = TokenKit.tokenize(
        "a-b-c",
        strategy: :char_group,
        split_on_chars: "-"
      )
      expect(tokens).to eq(["a", "b", "c"])
    end

    it "handles split_on_chars with repeated characters" do
      tokens = TokenKit.tokenize(
        "a,b,c",
        strategy: :char_group,
        split_on_chars: ",,"  # Duplicates are handled by HashSet
      )
      expect(tokens).to eq(["a", "b", "c"])
    end
  end
end
