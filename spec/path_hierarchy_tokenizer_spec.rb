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

  context "with preserve_patterns" do
    # Note: preserve_patterns has limitations with Path Hierarchy tokenizer
    # The apply_preserve_patterns function doesn't understand hierarchical structure
    # These tests are skipped until a custom implementation is developed

    it "preserves version patterns in paths" do
      TokenKit.configure do |config|
        config.strategy = :path_hierarchy
        config.delimiter = "/"
        config.lowercase = true
        config.preserve_patterns = [/v\d+\.\d+/, /V\d+/]
      end

      tokens = TokenKit.tokenize("/app/v2.1/V3/config")
      expect(tokens).to eq([
        "/app",
        "/app/v2.1",
        "/app/v2.1/V3",
        "/app/v2.1/V3/config"
      ])
    end

    it "preserves UUID patterns in paths" do
      TokenKit.configure do |config|
        config.strategy = :path_hierarchy
        config.delimiter = "/"
        config.lowercase = true
        config.preserve_patterns = [/[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}/]
      end

      uuid = "550e8400-e29b-41d4-a716-446655440000"
      tokens = TokenKit.tokenize("/data/#{uuid}/files")
      expect(tokens.join(" ")).to include(uuid)  # UUID should be preserved
    end

    it "preserves environment variables in paths" do
      TokenKit.configure do |config|
        config.strategy = :path_hierarchy
        config.delimiter = "/"
        config.lowercase = true
        config.preserve_patterns = [/PROD/, /DEV/, /TEST/]
      end

      tokens = TokenKit.tokenize("/env/PROD/app/DEV/test")
      expect(tokens).to eq([
        "/env",
        "/env/PROD",
        "/env/PROD/app",
        "/env/PROD/app/DEV",
        "/env/PROD/app/DEV/test"
      ])
    end

    it "preserves Windows-style paths" do
      TokenKit.configure do |config|
        config.strategy = :path_hierarchy
        config.delimiter = "\\"
        config.lowercase = true
        config.preserve_patterns = [/Program Files/, /System32/]
      end

      tokens = TokenKit.tokenize("C:\\Program Files\\System32\\app")
      expect(tokens).to eq([
        "c:",
        "c:\\Program Files",
        "c:\\Program Files\\System32",
        "c:\\Program Files\\System32\\app"
      ])
    end

    it "works with remove_punctuation" do
      TokenKit.configure do |config|
        config.strategy = :path_hierarchy
        config.delimiter = "/"
        config.lowercase = true
        config.remove_punctuation = true
        config.preserve_patterns = [/file\.txt/]
      end

      tokens = TokenKit.tokenize("/path/to/file.txt")
      expect(tokens).to eq([
        "/path",
        "/path/to",
        "/path/to/file.txt"
      ])
    end

    it "preserves API versioning patterns" do
      TokenKit.configure do |config|
        config.strategy = :path_hierarchy
        config.delimiter = "/"
        config.lowercase = true
        config.preserve_patterns = [/api\/v\d+/]
      end

      tokens = TokenKit.tokenize("api/v2/users/profile")
      expect(tokens).to eq([
        "api/v2",
        "api/v2/users",
        "api/v2/users/profile"
      ])
    end

    it "preserves timestamp patterns in log paths" do
      TokenKit.configure do |config|
        config.strategy = :path_hierarchy
        config.delimiter = "/"
        config.lowercase = true
        config.preserve_patterns = [/\d{4}-\d{2}-\d{2}/]
      end

      tokens = TokenKit.tokenize("/logs/2024-03-15/app.log")
      expect(tokens).to eq([
        "/logs",
        "/logs/2024-03-15",
        "/logs/2024-03-15/app.log"
      ])
    end
  end
end
