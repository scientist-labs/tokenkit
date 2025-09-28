RSpec.describe "Pattern Tokenizer" do
  after { TokenKit.reset }

  it "tokenizes using custom regex pattern" do
    TokenKit.configure do |config|
      config.strategy = :pattern
      config.regex = '\w+'
    end

    tokens = TokenKit.tokenize("Hello, world! Test.")
    expect(tokens).to eq(["hello", "world", "test"])
  end

  it "supports alphanumeric patterns" do
    TokenKit.configure do |config|
      config.strategy = :pattern
      config.regex = '[a-zA-Z0-9]+'
    end

    tokens = TokenKit.tokenize("Test123 abc456")
    expect(tokens).to eq(["test123", "abc456"])
  end

  it "supports custom delimiters" do
    TokenKit.configure do |config|
      config.strategy = :pattern
      config.regex = '[^,]+'
    end

    tokens = TokenKit.tokenize("apple,banana,cherry")
    expect(tokens).to eq(["apple", "banana", "cherry"])
  end
end