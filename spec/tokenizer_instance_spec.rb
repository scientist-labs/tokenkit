# frozen_string_literal: true

RSpec.describe TokenKit::Tokenizer do
  after(:each) do
    TokenKit.reset
  end
  describe "#initialize" do
    it "creates a tokenizer with default config" do
      tokenizer = TokenKit::Tokenizer.new
      expect(tokenizer).to be_a(TokenKit::Tokenizer)
      expect(tokenizer.config).to be_a(TokenKit::Configuration)
    end

    it "accepts a hash configuration" do
      tokenizer = TokenKit::Tokenizer.new(strategy: :whitespace, lowercase: false)
      expect(tokenizer.config.strategy).to eq(:whitespace)
      expect(tokenizer.config.lowercase).to eq(false)
    end

    it "accepts a Configuration object" do
      config = TokenKit::ConfigBuilder.new.tap do |c|
        c.strategy = :unicode
        c.lowercase = false
      end.build

      tokenizer = TokenKit::Tokenizer.new(config)
      expect(tokenizer.config.strategy).to eq(:unicode)
      expect(tokenizer.config.lowercase).to eq(false)
    end

    it "accepts a ConfigBuilder object" do
      builder = TokenKit::ConfigBuilder.new
      builder.strategy = :ngram
      builder.min_gram = 3
      builder.max_gram = 5

      tokenizer = TokenKit::Tokenizer.new(builder)
      expect(tokenizer.config.strategy).to eq(:ngram)
      expect(tokenizer.config.min_gram).to eq(3)
      expect(tokenizer.config.max_gram).to eq(5)
    end

    it "inherits from global defaults when using hash config" do
      TokenKit.configure do |c|
        c.strategy = :whitespace
        c.remove_punctuation = true
      end

      tokenizer = TokenKit::Tokenizer.new(lowercase: false)
      expect(tokenizer.config.strategy).to eq(:whitespace)
      expect(tokenizer.config.lowercase).to eq(false)
      expect(tokenizer.config.remove_punctuation).to eq(true)
    end
  end

  describe "#tokenize" do
    it "tokenizes text with instance configuration" do
      tok1 = TokenKit::Tokenizer.new(strategy: :whitespace)
      tok2 = TokenKit::Tokenizer.new(strategy: :unicode)

      text = "hello-world test"
      expect(tok1.tokenize(text)).to eq(["hello-world", "test"])
      expect(tok2.tokenize(text)).to eq(["hello", "world", "test"])
    end

    it "respects instance-specific lowercase setting" do
      tok1 = TokenKit::Tokenizer.new(strategy: :unicode, lowercase: true)
      tok2 = TokenKit::Tokenizer.new(strategy: :unicode, lowercase: false)

      text = "Hello World"
      expect(tok1.tokenize(text)).to eq(["hello", "world"])
      expect(tok2.tokenize(text)).to eq(["Hello", "World"])
    end

    it "supports preserve_patterns per instance" do
      tok1 = TokenKit::Tokenizer.new(
        strategy: :unicode,
        preserve_patterns: [/anti-\w+/i]
      )
      tok2 = TokenKit::Tokenizer.new(
        strategy: :unicode,
        preserve_patterns: []
      )

      text = "This anti-inflammatory medicine"
      expect(tok1.tokenize(text)).to include("anti-inflammatory")
      expect(tok2.tokenize(text)).not_to include("anti-inflammatory")
      expect(tok2.tokenize(text)).to include("anti", "inflammatory")
    end
  end

  describe "thread safety" do
    it "allows concurrent tokenization without blocking" do
      results = []
      mutex = Mutex.new

      threads = 10.times.map do |i|
        Thread.new do
          tokenizer = TokenKit::Tokenizer.new(
            strategy: i.even? ? :whitespace : :unicode,
            lowercase: i < 5
          )

          result = tokenizer.tokenize("Hello World Test")
          mutex.synchronize { results << result }
        end
      end

      threads.each(&:join)

      expect(results.size).to eq(10)
      # Should have different results based on config
      expect(results.uniq.size).to be > 1
    end

    it "isolates configuration between instances" do
      tok1 = nil
      tok2 = nil

      thread1 = Thread.new do
        tok1 = TokenKit::Tokenizer.new(strategy: :whitespace)
        sleep(0.01)  # Simulate work
        tok1.config.strategy
      end

      thread2 = Thread.new do
        tok2 = TokenKit::Tokenizer.new(strategy: :unicode)
        sleep(0.01)  # Simulate work
        tok2.config.strategy
      end

      result1 = thread1.value
      result2 = thread2.value

      expect(result1).to eq(:whitespace)
      expect(result2).to eq(:unicode)
    end

    it "handles rapid instance creation" do
      errors = []

      threads = 100.times.map do
        Thread.new do
          begin
            tok = TokenKit::Tokenizer.new(
              strategy: [:whitespace, :unicode, :letter].sample,
              lowercase: [true, false].sample
            )
            tok.tokenize("test text")
          rescue => e
            errors << e
          end
        end
      end

      threads.each(&:join)
      expect(errors).to be_empty
    end
  end

  describe "independence from global state" do
    it "is not affected by global configuration changes" do
      tokenizer = TokenKit::Tokenizer.new(strategy: :whitespace)

      # Change global config after instance creation
      TokenKit.configure do |c|
        c.strategy = :unicode
      end

      # Instance should still use its own config
      expect(tokenizer.tokenize("hello-world")).to eq(["hello-world"])
    end

    it "does not affect other instances" do
      tok1 = TokenKit::Tokenizer.new(strategy: :whitespace)
      tok2 = TokenKit::Tokenizer.new(strategy: :unicode)

      # Neither should affect the other
      expect(tok1.tokenize("hello-world")).to eq(["hello-world"])
      expect(tok2.tokenize("hello-world")).to eq(["hello", "world"])

      # Create a third instance - shouldn't be affected by previous ones
      tok3 = TokenKit::Tokenizer.new(strategy: :letter)
      expect(tok3.tokenize("hello123")).to eq(["hello"])
    end
  end

  describe "all strategies support" do
    strategies = {
      unicode: { text: "hello-world", expected_count: 2 },
      whitespace: { text: "hello world", expected_count: 2 },
      letter: { text: "hello123world", expected_count: 2 },
      lowercase: { text: "HeLLo WoRLD", expected_count: 2, includes: ["hello", "world"] },
      keyword: { text: "hello world", expected_first: "hello world" },
      sentence: { text: "Hello. World!", expected_count: 2 },
      ngram: { text: "test", min: 2, max: 3, includes: ["te", "tes"] },
      edge_ngram: { text: "test", min: 2, max: 3, includes: ["te", "tes"] },
      path_hierarchy: { text: "/usr/local/bin", delimiter: "/", includes: ["/usr"] },
      char_group: { text: "hello,world", split_chars: ",", expected_count: 2 },
      grapheme: { text: "hello", expected_count: 5 }
    }

    strategies.each do |strategy, opts|
      it "supports #{strategy} strategy" do
        config = { strategy: strategy }
        config[:min_gram] = opts[:min] if opts[:min]
        config[:max_gram] = opts[:max] if opts[:max]
        config[:delimiter] = opts[:delimiter] if opts[:delimiter]
        config[:split_on_chars] = opts[:split_chars] if opts[:split_chars]

        tokenizer = TokenKit::Tokenizer.new(config)
        result = tokenizer.tokenize(opts[:text])

        if opts[:expected_count]
          expect(result.size).to eq(opts[:expected_count])
        elsif opts[:expected_first]
          expect(result.first).to eq(opts[:expected_first])
        elsif opts[:includes]
          opts[:includes].each do |expected|
            expect(result).to include(expected)
          end
        end
      end
    end
  end

  describe "memory and resource management" do
    it "can create many instances without issues" do
      tokenizers = 100.times.map do |i|
        TokenKit::Tokenizer.new(strategy: i.even? ? :unicode : :whitespace)
      end

      tokenizers.each_with_index do |tok, i|
        result = tok.tokenize("test text")
        expect(result).to be_a(Array)
      end
    end

    it "releases resources properly" do
      # Create and discard many tokenizers
      1000.times do
        tok = TokenKit::Tokenizer.new(strategy: :unicode)
        tok.tokenize("test")
        # tok goes out of scope and should be GC'd
      end

      # Force GC
      GC.start

      # Should not have memory issues
      # (This is more of a smoke test)
      expect { TokenKit::Tokenizer.new.tokenize("test") }.not_to raise_error
    end
  end
end