# frozen_string_literal: true

RSpec.describe TokenKit::Configuration do
  describe "#initialize" do
    it "parses strategy from config hash" do
      config = TokenKit::Configuration.new({"strategy" => "unicode"})
      expect(config.strategy).to eq(:unicode)
    end

    it "defaults to unicode strategy when not provided" do
      config = TokenKit::Configuration.new({})
      expect(config.strategy).to eq(:unicode)
    end

    it "parses boolean flags" do
      config = TokenKit::Configuration.new({
        "lowercase" => false,
        "remove_punctuation" => true
      })
      expect(config.lowercase).to eq(false)
      expect(config.remove_punctuation).to eq(true)
    end

    it "parses preserve_patterns array" do
      config = TokenKit::Configuration.new({"preserve_patterns" => ["email", "url"]})
      expect(config.preserve_patterns).to eq(["email", "url"])
    end
  end

  describe "strategy predicates" do
    it "#pattern? returns true for pattern strategy" do
      config = TokenKit::Configuration.new({"strategy" => "pattern"})
      expect(config.pattern?).to eq(true)
    end

    it "#grapheme? returns true for grapheme strategy" do
      config = TokenKit::Configuration.new({"strategy" => "grapheme"})
      expect(config.grapheme?).to eq(true)
    end

    it "#edge_ngram? returns true for edge_ngram strategy" do
      config = TokenKit::Configuration.new({"strategy" => "edge_ngram"})
      expect(config.edge_ngram?).to eq(true)
    end

    it "#path_hierarchy? returns true for path_hierarchy strategy" do
      config = TokenKit::Configuration.new({"strategy" => "path_hierarchy"})
      expect(config.path_hierarchy?).to eq(true)
    end
  end

  describe "strategy-specific accessors" do
    it "#regex returns regex for pattern strategy" do
      config = TokenKit::Configuration.new({
        "strategy" => "pattern",
        "regex" => "\\w+"
      })
      expect(config.regex).to eq("\\w+")
    end

    it "#extended returns extended flag for grapheme strategy" do
      config = TokenKit::Configuration.new({
        "strategy" => "grapheme",
        "extended" => false
      })
      expect(config.extended).to eq(false)
    end

    it "#min_gram and #max_gram return values for edge_ngram strategy" do
      config = TokenKit::Configuration.new({
        "strategy" => "edge_ngram",
        "min_gram" => 3,
        "max_gram" => 7
      })
      expect(config.min_gram).to eq(3)
      expect(config.max_gram).to eq(7)
    end

    it "#delimiter returns delimiter for path_hierarchy strategy" do
      config = TokenKit::Configuration.new({
        "strategy" => "path_hierarchy",
        "delimiter" => "\\"
      })
      expect(config.delimiter).to eq("\\")
    end
  end

  describe "#to_h" do
    it "returns a copy of the config hash" do
      hash = {"strategy" => "unicode", "lowercase" => true}
      config = TokenKit::Configuration.new(hash)
      result = config.to_h
      expect(result).to eq(hash)
      expect(result.object_id).not_to eq(hash.object_id)
    end
  end

  describe "#inspect" do
    it "returns readable representation" do
      config = TokenKit::Configuration.new({
        "strategy" => "unicode",
        "lowercase" => true,
        "remove_punctuation" => false
      })
      expect(config.inspect).to eq("#<TokenKit::Configuration strategy=unicode lowercase=true remove_punctuation=false>")
    end
  end

  describe "integration with TokenKit module" do
    it "config_hash returns Configuration instance" do
      TokenKit.configure do |config|
        config.strategy = :edge_ngram
        config.min_gram = 2
        config.max_gram = 5
      end

      config = TokenKit.config_hash
      expect(config).to be_a(TokenKit::Configuration)
      expect(config.strategy).to eq(:edge_ngram)
      expect(config.min_gram).to eq(2)
      expect(config.max_gram).to eq(5)
    end

    it "Configuration reflects current tokenizer state" do
      TokenKit.reset
      TokenKit.configure do |config|
        config.strategy = :path_hierarchy
        config.delimiter = "|"
        config.lowercase = false
      end

      config = TokenKit.config_hash
      expect(config.strategy).to eq(:path_hierarchy)
      expect(config.delimiter).to eq("|")
      expect(config.lowercase).to eq(false)
    end
  end
end
