# frozen_string_literal: true

RSpec.describe "Per-Call Options" do
  after { TokenKit.reset }

  describe "grapheme strategy options" do
    it "respects extended option in one-off call" do
      tokens = TokenKit.tokenize(
        "நி",
        strategy: :grapheme,
        extended: false
      )
      expect(tokens.length).to be > 1
    end

    it "uses extended graphemes by default" do
      tokens = TokenKit.tokenize(
        "நி",
        strategy: :grapheme
      )
      expect(tokens).to eq(["நி"])
    end

    it "can override global extended setting" do
      TokenKit.configure do |config|
        config.strategy = :grapheme
        config.grapheme_extended = false
      end

      tokens = TokenKit.tokenize("👨‍👩‍👧‍👦", extended: true)
      expect(tokens).to eq(["👨‍👩‍👧‍👦"])
    end
  end

  describe "edge_ngram strategy options" do
    it "respects min_gram in one-off call" do
      tokens = TokenKit.tokenize(
        "hello",
        strategy: :edge_ngram,
        min_gram: 3,
        max_gram: 10
      )
      expect(tokens).to eq(["hel", "hell", "hello"])
    end

    it "respects max_gram in one-off call" do
      tokens = TokenKit.tokenize(
        "testing",
        strategy: :edge_ngram,
        min_gram: 2,
        max_gram: 4
      )
      expect(tokens).to eq(["te", "tes", "test"])
    end

    it "can override global min_gram and max_gram" do
      TokenKit.configure do |config|
        config.strategy = :edge_ngram
        config.min_gram = 2
        config.max_gram = 5
      end

      tokens = TokenKit.tokenize("search", min_gram: 3, max_gram: 4)
      expect(tokens).to eq(["sea", "sear"])
    end

    it "works with lowercase option" do
      tokens = TokenKit.tokenize(
        "HELLO",
        strategy: :edge_ngram,
        min_gram: 2,
        max_gram: 3,
        lowercase: false
      )
      expect(tokens).to eq(["HE", "HEL"])
    end

    it "works with remove_punctuation option" do
      tokens = TokenKit.tokenize(
        "test!",
        strategy: :edge_ngram,
        min_gram: 2,
        max_gram: 4,
        remove_punctuation: true
      )
      expect(tokens).to eq(["te", "tes", "test"])
    end
  end

  describe "path_hierarchy strategy options" do
    it "respects delimiter in one-off call" do
      tokens = TokenKit.tokenize(
        "C:\\Program Files\\Ruby",
        strategy: :path_hierarchy,
        delimiter: "\\",
        lowercase: false
      )
      expect(tokens).to eq([
        "C:",
        "C:\\Program Files",
        "C:\\Program Files\\Ruby"
      ])
    end

    it "can override global delimiter" do
      TokenKit.configure do |config|
        config.strategy = :path_hierarchy
        config.delimiter = "/"
      end

      tokens = TokenKit.tokenize("a|b|c", delimiter: "|")
      expect(tokens).to eq(["a", "a|b", "a|b|c"])
    end

    it "works with lowercase option" do
      tokens = TokenKit.tokenize(
        "/Usr/Local/Bin",
        strategy: :path_hierarchy,
        delimiter: "/",
        lowercase: true
      )
      expect(tokens).to eq([
        "/usr",
        "/usr/local",
        "/usr/local/bin"
      ])
    end

    it "works with remove_punctuation option" do
      tokens = TokenKit.tokenize(
        "path/to/file.txt",
        strategy: :path_hierarchy,
        delimiter: "/",
        remove_punctuation: true
      )
      expect(tokens).to eq([
        "path",
        "path/to",
        "path/to/filetxt"
      ])
    end

    it "handles custom delimiter with multiple characters" do
      tokens = TokenKit.tokenize(
        "a::b::c",
        strategy: :path_hierarchy,
        delimiter: "::"
      )
      expect(tokens).to eq(["a", "a::b", "a::b::c"])
    end
  end

  describe "pattern strategy with per-call regex" do
    it "uses provided regex pattern" do
      tokens = TokenKit.tokenize(
        "test@example.com and user@domain.org",
        strategy: :pattern,
        regex: /[\w.-]+@[\w.-]+\.\w+/
      )
      expect(tokens).to contain_exactly("test@example.com", "user@domain.org")
    end

    it "can override global regex pattern" do
      TokenKit.configure do |config|
        config.strategy = :pattern
        config.regex = "\\w+"
      end

      tokens = TokenKit.tokenize("test-123", regex: /\w+-\d+/)
      expect(tokens).to eq(["test-123"])
    end

    it "works with lowercase option" do
      tokens = TokenKit.tokenize(
        "ABC-123 DEF-456",
        strategy: :pattern,
        regex: /[A-Z]+-\d+/,
        lowercase: false
      )
      expect(tokens).to eq(["ABC-123", "DEF-456"])
    end
  end

  describe "combining multiple per-call options" do
    it "edge_ngram with min_gram, max_gram, and lowercase" do
      tokens = TokenKit.tokenize(
        "TEST",
        strategy: :edge_ngram,
        min_gram: 2,
        max_gram: 3,
        lowercase: true
      )
      expect(tokens).to eq(["te", "tes"])
    end

    it "path_hierarchy with delimiter and remove_punctuation" do
      tokens = TokenKit.tokenize(
        "a.b/c.d/e.f",
        strategy: :path_hierarchy,
        delimiter: "/",
        remove_punctuation: true
      )
      expect(tokens).to eq(["ab", "ab/cd", "ab/cd/ef"])
    end

    it "grapheme with extended and lowercase" do
      tokens = TokenKit.tokenize(
        "HELLO",
        strategy: :grapheme,
        extended: true,
        lowercase: true
      )
      expect(tokens).to eq(["h", "e", "l", "l", "o"])
    end
  end

  describe "per-call preserve patterns with unicode strategy" do
    it "preserves patterns in one-off call" do
      tokens = TokenKit.tokenize(
        "testing CODE-123 here",
        preserve: [/CODE-\d+/]
      )
      expect(tokens).to include("CODE-123")
      expect(tokens).to include("testing", "here")
    end

    it "preserves multiple patterns" do
      tokens = TokenKit.tokenize(
        "email user@example.com and CODE-123",
        preserve: [/[\w.-]+@[\w.-]+\.\w+/, /CODE-\d+/]
      )
      expect(tokens).to include("user@example.com", "CODE-123")
      expect(tokens).to include("email", "and")
    end

    it "works with lowercase option" do
      tokens = TokenKit.tokenize(
        "TEST CODE-123 HERE",
        preserve: [/CODE-\d+/],
        lowercase: true
      )
      expect(tokens).to include("CODE-123", "test", "here")
    end
  end

  describe "strategy switching in one-off calls" do
    it "switches from configured strategy to different strategy" do
      TokenKit.configure do |config|
        config.strategy = :unicode
        config.lowercase = true
      end

      tokens = TokenKit.tokenize(
        "hello world",
        strategy: :edge_ngram,
        min_gram: 2,
        max_gram: 3
      )
      expect(tokens).to eq(["he", "hel", "wo", "wor"])
    end

    it "preserves global config after one-off call" do
      TokenKit.configure do |config|
        config.strategy = :unicode
        config.lowercase = false
      end

      TokenKit.tokenize("test", strategy: :whitespace, lowercase: true)

      config = TokenKit.config_hash
      expect(config.strategy).to eq(:unicode)
      expect(config.lowercase).to eq(false)
    end
  end

  describe "invalid per-call options" do
    it "handles edge_ngram with only min_gram" do
      tokens = TokenKit.tokenize(
        "test",
        strategy: :edge_ngram,
        min_gram: 3
      )
      expect(tokens).to include("tes", "test")
    end

    it "handles edge_ngram with only max_gram" do
      tokens = TokenKit.tokenize(
        "hello",
        strategy: :edge_ngram,
        max_gram: 3
      )
      expect(tokens).to include("he", "hel")
    end

    it "handles path_hierarchy without delimiter" do
      tokens = TokenKit.tokenize(
        "/usr/local",
        strategy: :path_hierarchy
      )
      expect(tokens).to eq(["/usr", "/usr/local"])
    end
  end

  describe "option precedence" do
    it "per-call options override global config" do
      TokenKit.configure do |config|
        config.strategy = :edge_ngram
        config.min_gram = 2
        config.max_gram = 10
        config.lowercase = true
        config.remove_punctuation = false
      end

      tokens = TokenKit.tokenize(
        "TEST!",
        min_gram: 3,
        max_gram: 4,
        lowercase: false,
        remove_punctuation: true
      )
      expect(tokens).to eq(["TES", "TEST"])
    end

    it "unspecified per-call options use global config" do
      TokenKit.configure do |config|
        config.strategy = :edge_ngram
        config.min_gram = 2
        config.max_gram = 5
        config.lowercase = true
      end

      tokens = TokenKit.tokenize("TEST", max_gram: 3)
      expect(tokens).to eq(["te", "tes"])
    end
  end
end
