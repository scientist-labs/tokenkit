RSpec.describe "Whitespace Tokenizer" do
  before do
    TokenKit.configure do |config|
      config.strategy = :whitespace
    end
  end

  after { TokenKit.reset }

  it "splits on whitespace" do
    tokens = TokenKit.tokenize("Hello world test")
    expect(tokens).to eq(["hello", "world", "test"])
  end

  it "handles tabs and newlines" do
    tokens = TokenKit.tokenize("Hello\tworld\ntest")
    expect(tokens).to eq(["hello", "world", "test"])
  end

  it "handles multiple spaces" do
    tokens = TokenKit.tokenize("Hello    world")
    expect(tokens).to eq(["hello", "world"])
  end

  it "preserves punctuation within words" do
    tokens = TokenKit.tokenize("can't won't don't")
    expect(tokens).to eq(["can't", "won't", "don't"])
  end

  it "handles hyphens" do
    tokens = TokenKit.tokenize("anti-CD3 top-notch")
    expect(tokens).to eq(["anti-cd3", "top-notch"])
  end
end