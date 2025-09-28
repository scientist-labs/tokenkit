# TokenKit

Fast, Rust-backed word-level tokenization for Ruby with pattern preservation.

TokenKit is a Ruby wrapper around Rust's [unicode-segmentation](https://github.com/unicode-rs/unicode-segmentation) crate, providing lightweight, Unicode-aware tokenization designed for NLP pipelines, search applications, and text processing where you need consistent, high-quality word segmentation.

## Quickstart

```ruby
# Install the gem
gem install tokenkit

# Or add to your Gemfile
gem 'tokenkit'
```

```ruby
require 'tokenkit'

# Basic tokenization - handles Unicode, contractions, accents
TokenKit.tokenize("Hello, world! café can't")
# => ["hello", "world", "café", "can't"]

# Preserve domain-specific terms even when lowercasing
TokenKit.configure do |config|
  config.lowercase = true
  config.preserve_patterns = [
    /\d+ug/i,           # Measurements: 100ug
    /[A-Z][A-Z0-9]+/    # Gene names: BRCA1, TP53
  ]
end

TokenKit.tokenize("Patient received 100ug for BRCA1 study")
# => ["patient", "received", "100ug", "for", "BRCA1", "study"]
```

## Features

- **Three tokenization strategies**: whitespace, unicode (recommended), and custom regex patterns
- **Pattern preservation**: Keep domain-specific terms (gene names, measurements, antibodies) intact even with case normalization
- **Fast**: Rust-backed implementation (~100K docs/sec)
- **Thread-safe**: Safe for concurrent use
- **Simple API**: Configure once, use everywhere
- **Zero dependencies**: Pure Ruby API with Rust extension

## Tokenization Strategies

### Unicode (Recommended)

Uses Unicode word segmentation for proper handling of contractions, accents, and multi-language text:

```ruby
TokenKit.configure do |config|
  config.strategy = :unicode
  config.lowercase = true
end

TokenKit.tokenize("Don't worry about café!")
# => ["don't", "worry", "about", "café"]
```

### Whitespace

Simple whitespace splitting:

```ruby
TokenKit.configure do |config|
  config.strategy = :whitespace
  config.lowercase = true
end

TokenKit.tokenize("hello world")
# => ["hello", "world"]
```

### Pattern (Custom Regex)

Custom tokenization using regex patterns:

```ruby
TokenKit.configure do |config|
  config.strategy = :pattern
  config.regex = /[\w-]+/  # Keep words and hyphens
  config.lowercase = true
end

TokenKit.tokenize("anti-CD3 antibody")
# => ["anti-cd3", "antibody"]
```

## Pattern Preservation

Preserve domain-specific terms even when lowercasing:

```ruby
TokenKit.configure do |config|
  config.strategy = :unicode
  config.lowercase = true
  config.preserve_patterns = [
    /\d+(ug|mg|ml|units)/i,  # Measurements: 100ug, 50mg
    /anti-cd\d+/i,            # Antibodies: Anti-CD3, anti-CD28
    /[A-Z][A-Z0-9]+/          # Gene names: BRCA1, TP53, EGFR
  ]
end

text = "Patient received 100ug Anti-CD3 with BRCA1 mutation"
tokens = TokenKit.tokenize(text)
# => ["patient", "received", "100ug", "Anti-CD3", "with", "BRCA1", "mutation"]
```

Pattern matches maintain their original case despite `lowercase=true`.

## Configuration

### Global Configuration

```ruby
TokenKit.configure do |config|
  config.strategy = :unicode           # :whitespace, :unicode, :pattern
  config.lowercase = true              # Normalize to lowercase
  config.remove_punctuation = false    # Remove punctuation from tokens
  config.preserve_patterns = []        # Regex patterns to preserve
  config.regex = /\w+/                 # Only for :pattern strategy
end
```

### Per-Call Options

Override global config for specific calls:

```ruby
# Global: lowercase=true
TokenKit.configure { |c| c.lowercase = true }

# Override for one call
tokens = TokenKit.tokenize("BRCA1 Gene", lowercase: false)
# => ["BRCA1", "Gene"]
```

### Get Current Config

```ruby
config = TokenKit.config_hash
# => {
#   "strategy" => "unicode",
#   "lowercase" => true,
#   "remove_punctuation" => false,
#   "preserve_patterns" => ["\\d+ug"]
# }
```

### Reset to Defaults

```ruby
TokenKit.reset
```

## Use Cases

### Biotech/Life Sciences

```ruby
TokenKit.configure do |config|
  config.strategy = :unicode
  config.lowercase = true
  config.preserve_patterns = [
    /\d+(ug|mg|ml|ul|units)/i,  # Measurements
    /anti-[a-z0-9-]+/i,          # Antibodies
    /[A-Z]{2,10}/,               # Gene names (CDK10, BRCA1, TP53)
    /cd\d+/i,                    # Cell markers (CD3, CD4, CD8)
    /ig[gmaed]/i                 # Immunoglobulins (IgG, IgM)
  ]
end

text = "Anti-CD3 IgG antibody 100ug for BRCA1 research"
tokens = TokenKit.tokenize(text)
# => ["Anti-CD3", "IgG", "antibody", "100ug", "for", "BRCA1", "research"]
```

### E-commerce/Catalogs

```ruby
TokenKit.configure do |config|
  config.strategy = :unicode
  config.lowercase = true
  config.preserve_patterns = [
    /\$\d+(\.\d{2})?/,          # Prices: $99.99
    /\d+(-\d+)+/,               # SKUs: 123-456-789
    /\d+(mm|cm|inch)/i          # Dimensions: 10mm, 5cm
  ]
end

text = "Widget $49.99 SKU: 123-456 size: 10cm"
tokens = TokenKit.tokenize(text)
# => ["widget", "$49.99", "sku", "123-456", "size", "10cm"]
```

### Search Applications

```ruby
TokenKit.configure do |config|
  config.strategy = :unicode
  config.lowercase = true
  config.remove_punctuation = true
end

# Normalize search queries
query_tokens = TokenKit.tokenize(user_query)

# Match against normalized documents
doc_tokens = TokenKit.tokenize(document_text)
```

## Performance

- **Unicode tokenization**: ~100K docs/sec (negligible overhead vs. whitespace)
- **Pattern preservation**: Adds ~10-20% overhead depending on pattern complexity
- **Thread-safe**: Uses thread-local state for safe concurrent use

## Integration

TokenKit is designed to work with other gems in the scientist-labs ecosystem:

- **PhraseKit**: Use TokenKit for consistent phrase extraction
- **SpellKit**: Tokenize before spell correction
- **red-candle**: Tokenize before NER/embeddings

## Development

```bash
# Setup
bundle install
bundle exec rake compile

# Run tests
bundle exec rspec

# Run linter
bundle exec standardrb

# Build gem
gem build tokenkit.gemspec
```

## Requirements

- Ruby >= 3.1.0
- Rust toolchain (for building from source)

## License

MIT License. See [LICENSE.txt](LICENSE.txt) for details.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/scientist-labs/tokenkit.

This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](CODE_OF_CONDUCT.md).

## Credits

Built with:
- [Magnus](https://github.com/matsadler/magnus) for Ruby-Rust bindings
- [unicode-segmentation](https://github.com/unicode-rs/unicode-segmentation) for Unicode word boundaries
- [regex](https://github.com/rust-lang/regex) for pattern matching