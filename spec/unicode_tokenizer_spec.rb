RSpec.describe "Unicode Tokenizer" do
  before do
    TokenKit.configure do |config|
      config.strategy = :unicode
    end
  end

  after { TokenKit.reset }

  it "tokenizes using unicode word boundaries" do
    tokens = TokenKit.tokenize("Hello world")
    expect(tokens).to eq(["hello", "world"])
  end

  it "handles accented characters" do
    tokens = TokenKit.tokenize("café résumé naïve")
    expect(tokens).to eq(["café", "résumé", "naïve"])
  end

  it "handles asian scripts" do
    tokens = TokenKit.tokenize("こんにちは world")
    expect(tokens).to include("world")
  end

  it "treats apostrophes as part of words" do
    tokens = TokenKit.tokenize("can't won't")
    expect(tokens).to eq(["can't", "won't"])
  end

  it "treats hyphens as word boundaries" do
    tokens = TokenKit.tokenize("anti-CD3")
    expect(tokens).to eq(["anti", "cd3"])
  end

  context "with preserve patterns" do
    before do
      TokenKit.configure do |config|
        config.strategy = :unicode
        config.preserve_patterns = [/\d+ug/i, /anti-\w+/i]
      end
    end

    it "preserves patterns that match" do
      tokens = TokenKit.tokenize("Anti-CD3 antibody 100ug dose")
      expect(tokens).to include("100ug")
      expect(tokens).to include("antibody")
    end

    it "lowercases words normally" do
      tokens = TokenKit.tokenize("Anti-CD3 antibody")
      expect(tokens).to include("anti", "cd3", "antibody")
    end
  end
end