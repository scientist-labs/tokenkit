# Architecture Guide

This guide explains the internal architecture of TokenKit, design decisions, and how the Ruby and Rust components work together.

## Overview

TokenKit is a hybrid Ruby/Rust gem that leverages Rust's performance for tokenization while providing a friendly Ruby API. The architecture prioritizes:

1. **Performance**: Rust implementation with minimal FFI overhead
2. **Safety**: Thread-safe by design with proper error handling
3. **Flexibility**: Multiple tokenization strategies with unified API
4. **Maintainability**: Clear separation of concerns and trait-based design

```
┌─────────────────┐
│   Ruby Layer    │  lib/tokenkit.rb, lib/tokenkit/*.rb
├─────────────────┤
│  Magnus Bridge  │  FFI boundary (automatic serialization)
├─────────────────┤
│   Rust Layer    │  ext/tokenkit/src/*.rs
└─────────────────┘
```

## Component Architecture

### Ruby Layer (`lib/`)

```
lib/
├── tokenkit.rb           # Main module and API
├── tokenkit/
│   ├── version.rb        # Version constant
│   ├── tokenizer.rb      # Instance-based tokenizer
│   └── configuration.rb  # Config object with accessors
```

**Key Components:**

1. **TokenKit Module** (`lib/tokenkit.rb`):
   - Public API methods: `tokenize`, `configure`, `reset`
   - Delegates to Rust via Magnus
   - Handles option merging for per-call overrides

2. **Configuration** (`lib/tokenkit/configuration.rb`):
   - Ruby wrapper around config hash from Rust
   - Provides convenient accessors and predicates
   - Immutable once created

3. **Tokenizer Class** (`lib/tokenkit/tokenizer.rb`):
   - Instance-based API for specific configurations
   - Useful for bulk processing with different settings
   - Wraps module-level functions

### Rust Layer (`ext/tokenkit/src/`)

```
ext/tokenkit/src/
├── lib.rs              # Magnus bindings and caching
├── config.rs           # Configuration structs
├── error.rs            # Error types with thiserror
├── tokenizer/
│   ├── mod.rs          # Trait definition and factory
│   ├── base.rs         # Common functionality
│   ├── unicode.rs      # Unicode word boundaries
│   ├── whitespace.rs   # Simple whitespace splitting
│   ├── pattern.rs      # Regex-based tokenization
│   └── ...             # Other tokenizer implementations
```

**Key Components:**

1. **Entry Point** (`lib.rs`):
   - Magnus function exports
   - Tokenizer cache management
   - Configuration parsing and validation
   - Ruby ↔ Rust type conversion

2. **Configuration** (`config.rs`):
   - `TokenizerConfig` struct with all settings
   - `TokenizerStrategy` enum for strategy-specific options
   - Serde serialization for debugging

3. **Error Handling** (`error.rs`):
   - `TokenizerError` enum with thiserror
   - Automatic conversion to Ruby exceptions
   - Detailed error messages

4. **Tokenizer Trait** (`tokenizer/mod.rs`):
   ```rust
   pub trait Tokenizer: Send + Sync {
       fn tokenize(&self, text: &str) -> Vec<String>;
   }
   ```
   - Simple, focused interface
   - Thread-safe (`Send + Sync`)
   - Returns owned strings for Ruby

5. **Base Functionality** (`tokenizer/base.rs`):
   - `BaseTokenizerFields` for common state
   - Regex compilation for preserve_patterns
   - Shared helper functions

## Design Patterns

### 1. Strategy Pattern

Each tokenization strategy implements the `Tokenizer` trait:

```rust
// Factory function creates appropriate tokenizer
pub fn from_config(config: TokenizerConfig) -> Result<Box<dyn Tokenizer>> {
    match config.strategy {
        TokenizerStrategy::Unicode => Ok(Box::new(UnicodeTokenizer::new(config))),
        TokenizerStrategy::Whitespace => Ok(Box::new(WhitespaceTokenizer::new(config))),
        // ... other strategies
    }
}
```

### 2. Composition over Inheritance

Tokenizers compose `BaseTokenizerFields` for common functionality:

```rust
pub struct UnicodeTokenizer {
    base: BaseTokenizerFields,
}

impl UnicodeTokenizer {
    pub fn new(config: TokenizerConfig) -> Self {
        Self {
            base: BaseTokenizerFields::new(config),
        }
    }
}
```

### 3. Lazy Initialization with Caching

Tokenizer instances are created lazily and cached:

```rust
static DEFAULT_CACHE: Lazy<Mutex<TokenizerCache>> = Lazy::new(|| {
    Mutex::new(TokenizerCache {
        config: TokenizerConfig::default(),
        tokenizer: None,  // Created on first use
    })
});

fn tokenize(text: String) -> Result<Vec<String>, Error> {
    let mut cache = DEFAULT_CACHE.lock()?;

    if cache.tokenizer.is_none() {
        cache.tokenizer = Some(from_config(cache.config.clone())?);
    }

    Ok(cache.tokenizer.as_ref().unwrap().tokenize(&text))
}
```

### 4. Builder Pattern for Configuration

Configuration uses a builder-like pattern in Ruby:

```ruby
TokenKit.configure do |config|
  config.strategy = :unicode
  config.lowercase = true
  config.preserve_patterns = [...]
end
```

## Pattern Preservation Architecture

Pattern preservation is a key feature that required careful design:

### Problem

Different tokenizers split text differently, but preserve_patterns must work consistently across all strategies.

### Solution

Strategy-aware pattern preservation:

```rust
// Each tokenizer can provide custom tokenization for pattern gaps
pub fn apply_preserve_patterns_with_tokenizer<F>(
    tokens: Vec<String>,
    preserve_patterns: &[Regex],
    original_text: &str,
    config: &TokenizerConfig,
    tokenizer_fn: F,
) -> Vec<String>
where
    F: Fn(&str) -> Vec<String>
```

Example for CharGroup tokenizer:
```rust
// CharGroup uses its own delimiter logic for consistency
let tokens_with_patterns = apply_preserve_patterns_with_tokenizer(
    tokens,
    self.base.preserve_patterns(),
    text,
    &self.base.config,
    |text| self.tokenize_text(text),  // Uses CharGroup's split logic
);
```

## Thread Safety

TokenKit is thread-safe through careful design:

### Global State Protection

```rust
// Single mutex protects configuration and tokenizer
static DEFAULT_CACHE: Lazy<Mutex<TokenizerCache>> = Lazy::new(...)
```

### Tokenizer Trait Requirements

```rust
pub trait Tokenizer: Send + Sync {
    // Send: Can be transferred between threads
    // Sync: Can be shared between threads
}
```

### Immutable Tokenizers

Once created, tokenizers are immutable. Configuration changes create new instances:

```rust
fn configure(config_hash: RHash) -> Result<(), Error> {
    let config = parse_config_from_hash(config_hash)?;
    let mut cache = DEFAULT_CACHE.lock()?;
    cache.config = config;
    cache.tokenizer = None;  // Invalidate old tokenizer
    Ok(())
}
```

## Error Handling

Errors flow from Rust to Ruby with proper type conversion:

### Rust Side

```rust
#[derive(Error, Debug)]
pub enum TokenizerError {
    #[error("Invalid regex pattern '{pattern}': {error}")]
    InvalidRegex { pattern: String, error: String },

    #[error("Invalid n-gram configuration: min_gram ({min}) must be > 0 and <= max_gram ({max})")]
    InvalidNgramConfig { min: usize, max: usize },
    // ...
}
```

### Conversion to Ruby

```rust
impl From<TokenizerError> for magnus::Error {
    fn from(e: TokenizerError) -> Self {
        match e {
            TokenizerError::InvalidRegex { .. } => {
                magnus::Error::new(regexp_error_class(), e.to_string())
            }
            TokenizerError::InvalidNgramConfig { .. } => {
                magnus::Error::new(arg_error_class(), e.to_string())
            }
            // ...
        }
    }
}
```

### Ruby Side

```ruby
begin
  TokenKit.configure do |c|
    c.strategy = :pattern
    c.regex = "[invalid("
  end
rescue RegexpError => e
  puts "Invalid regex: #{e.message}"
end
```

## Performance Optimizations

### 1. Cached Tokenizer Instances

Eliminated regex recompilation on every tokenization:
- 110x speedup for pattern-heavy workloads
- Tokenizer created once, reused many times
- Cache invalidated only on configuration change

### 2. Zero-Copy String Slicing

Where possible, we work with string slices:

```rust
let before = &original_text[pos..start];  // No allocation
```

### 3. Capacity Hints

Pre-allocate vectors with estimated sizes:

```rust
let mut result = Vec::with_capacity(tokens.len() + preserved_spans.len());
```

### 4. Lazy String Allocation

Store indices instead of strings until needed:

```rust
// Store only positions during pattern matching
let mut preserved_spans: Vec<(usize, usize)> = Vec::with_capacity(32);

// Allocate strings only when building result
result.push(original_text[start..end].to_string());
```

## Magnus Bridge

Magnus provides seamless Ruby ↔ Rust interop:

### Type Conversions

```rust
// Ruby String → Rust String
fn tokenize(text: String) -> Result<Vec<String>, Error>

// Ruby Hash → Rust Config
fn configure(config_hash: RHash) -> Result<(), Error>

// Rust Vec<String> → Ruby Array
Ok(tokenizer.tokenize(&text))  // Automatic conversion
```

### Function Export

```rust
#[magnus::init]
fn init(_ruby: &magnus::Ruby) -> Result<(), Error> {
    let module = define_module("TokenKit")?;

    module.define_module_function("_tokenize", function!(tokenize, 1))?;
    module.define_module_function("_configure", function!(configure, 1))?;
    // ...
}
```

### Memory Management

Magnus handles memory management automatically:
- Rust strings converted to Ruby strings
- Ruby GC manages Ruby objects
- Rust objects dropped when out of scope

## Testing Strategy

### Ruby Tests (`spec/`)

- Integration tests for public API
- Test all tokenization strategies
- Verify Ruby-specific behavior
- Edge cases and error conditions

### Rust Tests

Currently, we rely on Ruby tests for coverage. Future work could add:
- Unit tests for tokenizer implementations
- Property-based testing for pattern preservation
- Benchmarks in Rust

### Coverage

- 94.12% line coverage
- 87.8% branch coverage
- All tokenizers thoroughly tested
- Error paths verified

## Build System

### Compilation

1. `rake compile` invokes cargo
2. Cargo builds with release optimizations:
   ```toml
   [profile.release]
   lto = true           # Link-time optimization
   codegen-units = 1    # Better optimization
   ```
3. Shared library copied to lib/

### Cross-Platform

- macOS: `.bundle` extension
- Linux: `.so` extension
- Windows: `.dll` extension

Magnus handles platform differences automatically.

## Future Architecture Improvements

### 1. Parallel Tokenization

For very large texts, parallelize using Rayon:
```rust
use rayon::prelude::*;

large_text.par_lines()
    .flat_map(|line| tokenizer.tokenize(line))
    .collect()
```

### 2. Streaming API

For huge documents:
```rust
pub trait StreamingTokenizer {
    fn tokenize_stream(&self, reader: impl BufRead) -> impl Iterator<Item = String>;
}
```

### 3. Custom Allocators

Investigate jemalloc or mimalloc for better performance:
```toml
[dependencies]
tikv-jemallocator = "0.5"
```

### 4. SIMD Optimizations

Use SIMD for character scanning:
```rust
use std::simd::*;
// Vectorized character matching
```

### 5. Regex Set Optimization

When multiple patterns, use regex::RegexSet:
```rust
use regex::RegexSet;

let patterns = RegexSet::new(&[...]).unwrap();
let matches: Vec<_> = patterns.matches(text).into_iter().collect();
```

## Conclusion

TokenKit's architecture balances performance, safety, and usability through:

- Clean separation between Ruby API and Rust implementation
- Trait-based design for extensibility
- Intelligent caching for performance
- Comprehensive error handling
- Thread-safe by design

The hybrid Ruby/Rust approach provides the best of both worlds: Ruby's elegant API and Rust's performance.