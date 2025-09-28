RSpec.describe "Sentence Tokenizer" do
  before do
    TokenKit.configure do |config|
      config.strategy = :sentence
      config.lowercase = false
    end
  end

  after { TokenKit.reset }

  it "splits text into sentences" do
    text = "Hello world! How are you? I am fine."
    tokens = TokenKit.tokenize(text)
    expect(tokens).to eq(["Hello world! ", "How are you? ", "I am fine."])
  end

  it "handles multiple punctuation marks" do
    text = "Really?! Yes... Maybe."
    tokens = TokenKit.tokenize(text)
    expect(tokens).to eq(["Really?! ", "Yes... ", "Maybe."])
  end

  it "handles period-ending sentences" do
    text = "First sentence. Second sentence. Third sentence."
    tokens = TokenKit.tokenize(text)
    expect(tokens.size).to eq(3)
  end

  it "handles newlines between sentences" do
    text = "First sentence.\nSecond sentence."
    tokens = TokenKit.tokenize(text)
    expect(tokens.size).to eq(2)
  end

  it "returns empty array for empty string" do
    tokens = TokenKit.tokenize("")
    expect(tokens).to eq([])
  end

  it "handles single sentence without punctuation" do
    text = "Hello world"
    tokens = TokenKit.tokenize(text)
    expect(tokens).to eq(["Hello world"])
  end

  context "with lowercase option" do
    before do
      TokenKit.configure do |config|
        config.strategy = :sentence
        config.lowercase = true
      end
    end

    it "lowercases the sentences" do
      text = "Hello World! How Are You?"
      tokens = TokenKit.tokenize(text)
      expect(tokens).to eq(["hello world! ", "how are you?"])
    end
  end

  context "with remove_punctuation option" do
    before do
      TokenKit.configure do |config|
        config.strategy = :sentence
        config.lowercase = false
        config.remove_punctuation = true
      end
    end

    it "removes punctuation from sentences" do
      text = "Hello, world! How are you?"
      tokens = TokenKit.tokenize(text)
      expect(tokens.all? { |t| !t.match?(/[[:punct:]]/) }).to be true
    end
  end
end
