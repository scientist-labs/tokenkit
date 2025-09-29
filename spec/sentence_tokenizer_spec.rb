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

  context "with preserve_patterns" do
    it "preserves acronyms in sentences" do
      TokenKit.configure do |config|
        config.strategy = :sentence
        config.lowercase = true
        config.preserve_patterns = [/[A-Z]{2,}/]
      end

      text = "The FDA approved the drug. MIT has great programs."
      tokens = TokenKit.tokenize(text)
      expect(tokens[0]).to include("FDA")
      expect(tokens[1]).to include("MIT")
    end

    it "preserves scientific names" do
      TokenKit.configure do |config|
        config.strategy = :sentence
        config.lowercase = true
        config.preserve_patterns = [/E\. coli/, /H\. pylori/]
      end

      text = "The study found E. coli in the sample. H. pylori was also detected."
      tokens = TokenKit.tokenize(text)
      expect(tokens[0]).to eq("the study found E. coli in the sample. ")
      expect(tokens[1]).to eq("H. pylori was also detected.")
    end

    it "preserves gene names across sentences" do
      TokenKit.configure do |config|
        config.strategy = :sentence
        config.lowercase = true
        config.preserve_patterns = [/BRCA\d+/, /TP\d+/]
      end

      text = "BRCA1 mutations are significant. TP53 also plays a role."
      tokens = TokenKit.tokenize(text)
      expect(tokens[0]).to eq("BRCA1 mutations are significant. ")
      expect(tokens[1]).to eq("TP53 also plays a role.")
    end

    it "preserves measurements in sentences" do
      TokenKit.configure do |config|
        config.strategy = :sentence
        config.lowercase = true
        config.preserve_patterns = [/\d+(mg|kg|ml|µg)/]
      end

      text = "Administer 100mg twice daily. Maximum dose is 5ml per hour."
      tokens = TokenKit.tokenize(text)
      expect(tokens[0]).to include("100mg")
      expect(tokens[1]).to include("5ml")
    end

    it "preserves product codes" do
      TokenKit.configure do |config|
        config.strategy = :sentence
        config.lowercase = true
        config.preserve_patterns = [/SKU-\d+/, /REF-[A-Z0-9]+/]
      end

      text = "Order SKU-12345 today. Reference REF-ABC123 for details."
      tokens = TokenKit.tokenize(text)
      expect(tokens[0]).to eq("order SKU-12345 today. ")
      expect(tokens[1]).to eq("reference REF-ABC123 for details.")
    end

    it "preserves multiple pattern types" do
      TokenKit.configure do |config|
        config.strategy = :sentence
        config.lowercase = true
        config.preserve_patterns = [
          /USA/,
          /v\d+\.\d+/,
          /COVID-19/
        ]
      end

      text = "USA released v2.0 guidelines. COVID-19 protocols updated."
      tokens = TokenKit.tokenize(text)
      expect(tokens[0]).to eq("USA released v2.0 guidelines. ")
      expect(tokens[1]).to eq("COVID-19 protocols updated.")
    end

    it "works without lowercase" do
      TokenKit.configure do |config|
        config.strategy = :sentence
        config.lowercase = false
        config.preserve_patterns = [/TEST/]
      end

      # When lowercase is false, preserve_patterns has no effect
      text = "This is a TEST sentence. Another TEST here."
      tokens = TokenKit.tokenize(text)
      expect(tokens[0]).to eq("This is a TEST sentence. ")
      expect(tokens[1]).to eq("Another TEST here.")
    end
  end
end
