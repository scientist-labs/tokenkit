RSpec.describe "URL/Email Tokenizer" do
  before do
    TokenKit.configure do |config|
      config.strategy = :url_email
      config.lowercase = true
    end
  end

  after { TokenKit.reset }

  it "preserves email addresses as single tokens" do
    tokens = TokenKit.tokenize("Contact support@example.com for help")
    expect(tokens).to include("support@example.com")
    expect(tokens).to include("contact", "for", "help")
  end

  it "preserves multiple email addresses" do
    tokens = TokenKit.tokenize("Email alice@example.com or bob@test.org")
    expect(tokens).to include("alice@example.com", "bob@test.org")
    expect(tokens).to include("email", "or")
  end

  it "preserves HTTP URLs as single tokens" do
    tokens = TokenKit.tokenize("Visit http://example.com for more info")
    expect(tokens).to include("http://example.com")
    expect(tokens).to include("visit", "for", "more", "info")
  end

  it "preserves HTTPS URLs as single tokens" do
    tokens = TokenKit.tokenize("Visit https://example.com for more info")
    expect(tokens).to include("https://example.com")
    expect(tokens).to include("visit", "for", "more", "info")
  end

  it "preserves URLs with paths" do
    tokens = TokenKit.tokenize("Check https://example.com/products/laptops for details")
    expect(tokens).to include("https://example.com/products/laptops")
    expect(tokens).to include("check", "for", "details")
  end

  it "handles text with both emails and URLs" do
    text = "Contact support@example.com or visit https://example.com"
    tokens = TokenKit.tokenize(text)
    expect(tokens).to include("support@example.com", "https://example.com")
    expect(tokens).to include("contact", "or", "visit")
  end

  it "handles text with no emails or URLs" do
    tokens = TokenKit.tokenize("Hello world this is plain text")
    expect(tokens).to eq(["hello", "world", "this", "is", "plain", "text"])
  end

  it "returns empty array for empty string" do
    tokens = TokenKit.tokenize("")
    expect(tokens).to eq([])
  end

  it "handles email at start of text" do
    tokens = TokenKit.tokenize("admin@test.com sent you a message")
    expect(tokens).to eq(["admin@test.com", "sent", "you", "a", "message"])
  end

  it "handles URL at end of text" do
    tokens = TokenKit.tokenize("Visit us at https://example.com")
    expect(tokens).to eq(["visit", "us", "at", "https://example.com"])
  end

  context "with lowercase option" do
    before do
      TokenKit.configure do |config|
        config.strategy = :url_email
        config.lowercase = true
      end
    end

    it "lowercases regular words but not domain case sensitivity" do
      tokens = TokenKit.tokenize("Contact SUPPORT@EXAMPLE.COM please")
      expect(tokens).to include("support@example.com")
      expect(tokens).to include("contact", "please")
    end

    it "lowercases URLs" do
      tokens = TokenKit.tokenize("Visit HTTPS://EXAMPLE.COM")
      expect(tokens).to include("https://example.com")
    end
  end

  context "with lowercase disabled" do
    before do
      TokenKit.configure do |config|
        config.strategy = :url_email
        config.lowercase = false
      end
    end

    it "preserves case in all tokens" do
      tokens = TokenKit.tokenize("Contact SUPPORT@EXAMPLE.COM Please")
      expect(tokens).to include("SUPPORT@EXAMPLE.COM")
      expect(tokens).to include("Contact", "Please")
    end
  end

  context "with remove_punctuation option" do
    before do
      TokenKit.configure do |config|
        config.strategy = :url_email
        config.lowercase = true
        config.remove_punctuation = true
      end
    end

    it "does not remove punctuation from URLs and emails" do
      text = "Visit https://example.com or email test@example.com today!"
      tokens = TokenKit.tokenize(text)
      expect(tokens).to include("https://example.com", "test@example.com")
      expect(tokens).to include("visit", "or", "email", "today")
    end
  end

  context "complex URLs" do
    it "handles URLs with query parameters" do
      tokens = TokenKit.tokenize("Search https://example.com/search?q=test")
      expect(tokens).to include("https://example.com/search?q=test")
    end

    it "handles URLs with ports" do
      tokens = TokenKit.tokenize("Connect to http://localhost:3000")
      expect(tokens).to include("http://localhost:3000")
    end

    it "handles URLs without schemes" do
      tokens = TokenKit.tokenize("Visit example.com for details")
      expect(tokens).to include("example.com")
      expect(tokens).to include("visit", "for", "details")
    end

    it "handles URLs in parentheses" do
      tokens = TokenKit.tokenize("See docs (https://example.com) here")
      expect(tokens).to include("https://example.com")
      expect(tokens).to include("see", "docs", "here")
    end
  end

  context "email variations" do
    it "handles emails with dots" do
      tokens = TokenKit.tokenize("Email first.last@example.com")
      expect(tokens).to include("first.last@example.com")
    end

    it "handles emails with plus addressing" do
      tokens = TokenKit.tokenize("Send to user+tag@example.com")
      expect(tokens).to include("user+tag@example.com")
    end

    it "handles emails with numbers" do
      tokens = TokenKit.tokenize("Contact user123@test456.com")
      expect(tokens).to include("user123@test456.com")
    end
  end

  context "use cases" do
    it "tokenizes customer support messages" do
      text = "Please contact support@company.com or visit https://help.company.com"
      tokens = TokenKit.tokenize(text)
      expect(tokens).to include("support@company.com", "https://help.company.com")
    end

    it "tokenizes product descriptions with links" do
      text = "Buy now at https://store.example.com or email sales@example.com"
      tokens = TokenKit.tokenize(text)
      expect(tokens).to include("https://store.example.com", "sales@example.com")
    end
  end

  context "with preserve_patterns" do
    it "preserves patterns alongside URLs and emails" do
      TokenKit.configure do |config|
        config.strategy = :url_email
        config.lowercase = true
        config.preserve_patterns = [/TICKET-\d+/, /SKU-\d+/]
      end

      tokens = TokenKit.tokenize("TICKET-123 email support@example.com about SKU-456")
      expect(tokens).to eq(["TICKET-123", "email", "support@example.com", "about", "SKU-456"])
    end

    it "preserves gene names with scientific URLs" do
      TokenKit.configure do |config|
        config.strategy = :url_email
        config.lowercase = true
        config.preserve_patterns = [/BRCA\d+/, /TP\d+/]
      end

      tokens = TokenKit.tokenize("BRCA1 info at https://www.ncbi.nlm.nih.gov/gene/672 and TP53")
      expect(tokens).to eq(["BRCA1", "info", "at", "https://www.ncbi.nlm.nih.gov/gene/672", "and", "TP53"])
    end

    it "preserves measurements in support content" do
      TokenKit.configure do |config|
        config.strategy = :url_email
        config.lowercase = true
        config.preserve_patterns = [/\d+(GB|MB|KB)/i]
      end

      tokens = TokenKit.tokenize("Upload 100MB to https://upload.example.com or email admin@example.com")
      expect(tokens).to eq(["upload", "100MB", "to", "https://upload.example.com", "or", "email", "admin@example.com"])
    end

    it "handles overlapping patterns" do
      TokenKit.configure do |config|
        config.strategy = :url_email
        config.lowercase = true
        config.preserve_patterns = [/support@example\.com/]
      end

      # URL detector already finds support@example.com as email, pattern should not duplicate
      tokens = TokenKit.tokenize("Contact support@example.com today")
      expect(tokens).to eq(["contact", "support@example.com", "today"])
    end

    it "preserves version patterns with download URLs" do
      TokenKit.configure do |config|
        config.strategy = :url_email
        config.lowercase = true
        config.preserve_patterns = [/v\d+\.\d+\.\d+/]
      end

      tokens = TokenKit.tokenize("Download v2.1.3 from https://downloads.example.com")
      expect(tokens).to eq(["download", "v2.1.3", "from", "https://downloads.example.com"])
    end

    it "works with remove_punctuation" do
      TokenKit.configure do |config|
        config.strategy = :url_email
        config.lowercase = true
        config.remove_punctuation = true
        config.preserve_patterns = [/API-\d+/]
      end

      tokens = TokenKit.tokenize("API-123! Visit https://api.example.com now!")
      expect(tokens).to eq(["API-123", "visit", "https://api.example.com", "now"])
    end

    it "preserves hashtags and mentions" do
      TokenKit.configure do |config|
        config.strategy = :url_email
        config.lowercase = true
        config.preserve_patterns = [/#\w+/, /@\w+/]
      end

      tokens = TokenKit.tokenize("#News @User check https://example.com")
      expect(tokens).to eq(["#News", "@User", "check", "https://example.com"])
    end
  end
end
