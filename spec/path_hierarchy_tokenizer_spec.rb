RSpec.describe "Path Hierarchy Tokenizer" do
  before do
    TokenKit.configure do |config|
      config.strategy = :path_hierarchy
      config.delimiter = "/"
      config.lowercase = false
    end
  end

  after { TokenKit.reset }

  it "generates hierarchy tokens for absolute path" do
    tokens = TokenKit.tokenize("/usr/local/bin/ruby")
    expect(tokens).to eq([
      "/usr",
      "/usr/local",
      "/usr/local/bin",
      "/usr/local/bin/ruby"
    ])
  end

  it "generates hierarchy tokens for relative path" do
    tokens = TokenKit.tokenize("usr/local/bin")
    expect(tokens).to eq([
      "usr",
      "usr/local",
      "usr/local/bin"
    ])
  end

  it "handles single level path" do
    tokens = TokenKit.tokenize("/home")
    expect(tokens).to eq(["/home"])
  end

  it "handles path without leading slash" do
    tokens = TokenKit.tokenize("projects/ruby")
    expect(tokens).to eq([
      "projects",
      "projects/ruby"
    ])
  end

  it "returns empty array for empty string" do
    tokens = TokenKit.tokenize("")
    expect(tokens).to eq([])
  end

  it "handles whitespace-only string" do
    tokens = TokenKit.tokenize("   ")
    expect(tokens).to eq([])
  end

  context "with custom delimiter" do
    before do
      TokenKit.configure do |config|
        config.strategy = :path_hierarchy
        config.delimiter = "\\"
        config.lowercase = false
      end
    end

    it "uses custom delimiter for Windows paths" do
      tokens = TokenKit.tokenize("C:\\Program Files\\Ruby")
      expect(tokens).to eq([
        "C:",
        "C:\\Program Files",
        "C:\\Program Files\\Ruby"
      ])
    end
  end

  context "with URL paths" do
    it "generates hierarchy for URL structure" do
      tokens = TokenKit.tokenize("docs/api/reference/tokenizers")
      expect(tokens).to eq([
        "docs",
        "docs/api",
        "docs/api/reference",
        "docs/api/reference/tokenizers"
      ])
    end
  end

  context "with lowercase option" do
    before do
      TokenKit.configure do |config|
        config.strategy = :path_hierarchy
        config.delimiter = "/"
        config.lowercase = true
      end
    end

    it "lowercases the hierarchy tokens" do
      tokens = TokenKit.tokenize("/Users/Admin/Documents")
      expect(tokens).to eq([
        "/users",
        "/users/admin",
        "/users/admin/documents"
      ])
    end
  end

  context "with remove_punctuation option" do
    before do
      TokenKit.configure do |config|
        config.strategy = :path_hierarchy
        config.delimiter = "/"
        config.lowercase = false
        config.remove_punctuation = true
      end
    end

    it "removes punctuation but preserves path structure" do
      tokens = TokenKit.tokenize("path/to/file.txt")
      expect(tokens).to eq([
        "path",
        "path/to",
        "path/to/filetxt"
      ])
    end
  end

  context "use cases" do
    it "handles file system paths" do
      tokens = TokenKit.tokenize("/var/log/nginx/access.log")
      expect(tokens).to eq([
        "/var",
        "/var/log",
        "/var/log/nginx",
        "/var/log/nginx/access.log"
      ])
    end

    it "handles category hierarchies" do
      tokens = TokenKit.tokenize("electronics/computers/laptops/gaming")
      expect(tokens).to eq([
        "electronics",
        "electronics/computers",
        "electronics/computers/laptops",
        "electronics/computers/laptops/gaming"
      ])
    end
  end
end