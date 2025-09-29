# Performance Guide

TokenKit is optimized for high-throughput tokenization with minimal memory overhead. This guide covers performance characteristics, optimization techniques, and best practices.

## Performance Benchmarks

### Baseline Performance

TokenKit can process ~100,000 documents per second for basic Unicode tokenization on modern hardware (Apple M-series, Intel i7+).

| Tokenizer | Operations/sec | Relative Speed | Use Case |
|-----------|---------------|----------------|----------|
| Lowercase | 870,000 | 1.0x (fastest) | Case normalization |
| Whitespace | 850,000 | 1.02x | Simple splitting |
| Unicode | 870,000 | 1.0x | **Recommended default** |
| Letter | 850,000 | 1.02x | Aggressive splitting |
| Pattern (simple) | 500,000 | 1.74x slower | Custom patterns |
| URL/Email | 400,000 | 2.17x slower | Web content |
| EdgeNgram | 388,000 | 2.24x slower | Autocomplete |
| Ngram | 350,000 | 2.49x slower | Fuzzy matching |
| CharGroup | 400,000 | 2.17x slower | CSV parsing |
| PathHierarchy | 300,000 | 2.90x slower | Path navigation |
| Pattern (complex) | 24,000 | 36x slower | Complex regex |
| Grapheme | 200,000 | 4.35x slower | Emoji handling |
| Sentence | 150,000 | 5.80x slower | Sentence splitting |
| Keyword | 1,000,000 | 0.87x faster | No splitting |

### Pattern Preservation Impact

Pattern preservation adds overhead proportional to pattern complexity:

| Configuration | Ops/sec | Impact |
|--------------|---------|--------|
| No patterns | 870,000 | Baseline |
| 1 simple pattern | 600,000 | -31% |
| 4 patterns | 409,000 | -53% |
| 10 complex patterns | 150,000 | -83% |

## Optimization Techniques

### 1. Tokenizer Instance Caching (110x speedup)

**Problem**: Creating a new tokenizer and compiling regexes on every call.

**Solution**: Cache tokenizer instances and invalidate only on configuration changes.

```rust
// Before: Created fresh tokenizer every time
fn tokenize(text: String) -> Vec<String> {
    let tokenizer = from_config(config)?;  // Recompiled regexes!
    tokenizer.tokenize(&text)
}

// After: Cached tokenizer instance
static DEFAULT_CACHE: Lazy<Mutex<TokenizerCache>> = Lazy::new(|| {
    Mutex::new(TokenizerCache {
        config: TokenizerConfig::default(),
        tokenizer: None,  // Created once, reused many times
    })
});
```

**Impact**:
- With preserve patterns: 3,638 → 409,472 ops/sec (110x faster)
- Without patterns: 500,000 → 870,000 ops/sec (1.74x faster)

### 2. Reduced String Allocations (20-30% improvement)

**Problem**: Creating intermediate string copies during pattern preservation.

**Solution**: Work with indices, allocate strings only when needed.

```rust
// Before: Stored strings eagerly
let mut preserved_spans: Vec<(usize, usize, String)> = Vec::new();
for mat in pattern.find_iter(text) {
    preserved_spans.push((mat.start(), mat.end(), mat.as_str().to_string()));
}

// After: Store indices, extract strings lazily
let mut preserved_spans: Vec<(usize, usize)> = Vec::with_capacity(32);
for mat in pattern.find_iter(text) {
    preserved_spans.push((mat.start(), mat.end()));
}
// Extract string only when building final result
result.push(original_text[start..end].to_string());
```

### 3. In-Place Post-Processing

**Problem**: Creating new vectors for lowercase and punctuation removal.

**Solution**: Modify vectors in-place.

```rust
// Before: Created new vector
tokens = tokens.into_iter().map(|t| t.to_lowercase()).collect();

// After: Modify in place
for token in tokens.iter_mut() {
    *token = token.to_lowercase();
}
```

### 4. Pre-Allocated Vectors

**Problem**: Dynamic vector growth causes reallocations.

**Solution**: Pre-allocate with estimated capacity.

```rust
// Estimate result size
let mut result = Vec::with_capacity(tokens.len() + preserved_spans.len());
```

### 5. Optimized Sorting

**Problem**: Stable sort is slower than necessary.

**Solution**: Use `sort_unstable_by` for better performance.

```rust
// Before
spans.sort_by(|a, b| a.0.cmp(&b.0));

// After
spans.sort_unstable_by(|a, b| a.0.cmp(&b.0));
```

## Running Benchmarks

TokenKit includes comprehensive benchmarks to measure performance:

```bash
# Install benchmark gems
bundle add benchmark-ips benchmark-memory

# Run all benchmarks
ruby benchmarks/tokenizer_benchmark.rb

# Run specific benchmark suites
ruby benchmarks/tokenizer_benchmark.rb tokenizers  # Strategy comparison
ruby benchmarks/tokenizer_benchmark.rb config      # Configuration impact
ruby benchmarks/tokenizer_benchmark.rb size        # Text size scaling
ruby benchmarks/tokenizer_benchmark.rb memory      # Memory usage
```

### Creating Custom Benchmarks

```ruby
require 'benchmark/ips'
require 'tokenkit'

text = "Your sample text here"

Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)

  x.report("Unicode") do
    TokenKit.configure { |c| c.strategy = :unicode }
    TokenKit.tokenize(text)
  end

  x.report("Pattern") do
    TokenKit.configure { |c| c.strategy = :pattern; c.regex = /\w+/ }
    TokenKit.tokenize(text)
  end

  x.compare!
end
```

## Performance Best Practices

### 1. Choose the Right Tokenizer

- **Default to Unicode**: Best balance of correctness and performance
- **Use Whitespace**: When you know text is already well-formatted
- **Avoid Complex Patterns**: Each regex pattern has compilation and matching overhead

### 2. Minimize Pattern Preservation

```ruby
# Bad: Many overlapping patterns
config.preserve_patterns = [
  /\d+/,
  /\d+mg/,
  /\d+ug/,
  /\d+ml/
]

# Good: Single comprehensive pattern
config.preserve_patterns = [
  /\d+(mg|ug|ml)/
]
```

### 3. Reuse Tokenizer Instances

```ruby
# Good: Configure once, use many times
TokenKit.configure do |config|
  config.strategy = :unicode
  config.preserve_patterns = [...]
end

documents.each do |doc|
  tokens = TokenKit.tokenize(doc)  # Uses cached instance
end

# Avoid: Reconfiguring repeatedly
documents.each do |doc|
  TokenKit.configure { |c| c.strategy = :unicode }  # Invalidates cache!
  tokens = TokenKit.tokenize(doc)
end
```

### 4. Use Instance API for Bulk Processing

```ruby
# For bulk processing with different configurations
tokenizer = TokenKit::Tokenizer.new(
  strategy: :unicode,
  preserve_patterns: [...]
)

# Reuse the same instance
documents.map { |doc| tokenizer.tokenize(doc) }
```

### 5. Consider Memory vs Speed Tradeoffs

- **N-gram tokenizers**: Generate many tokens, higher memory usage
- **Pattern preservation**: Increases memory for regex storage
- **Remove punctuation**: Reduces token count, saves memory

## Thread Safety and Concurrency

TokenKit is thread-safe and can be used in concurrent environments:

```ruby
# Safe: Each thread uses the global cached tokenizer
threads = 10.times.map do
  Thread.new do
    100.times do
      TokenKit.tokenize("some text")
    end
  end
end
threads.each(&:join)
```

Performance in concurrent environments:
- Single-threaded: ~870k ops/sec
- Multi-threaded (10 threads): ~850k ops/sec (minimal overhead)

## Memory Usage

Memory usage varies by tokenizer and options:

| Configuration | Memory/Operation | Notes |
|--------------|------------------|-------|
| Basic Unicode | ~500 bytes | Minimal overhead |
| With preserve patterns | ~1-2 KB | Regex storage |
| EdgeNgram (max=10) | ~2-5 KB | Multiple tokens generated |
| Ngram (min=2, max=3) | ~3-8 KB | Many substring tokens |

### Memory Profiling

```ruby
require 'benchmark/memory'

Benchmark.memory do |x|
  x.report("Unicode") do
    TokenKit.configure { |c| c.strategy = :unicode }
    100.times { TokenKit.tokenize("sample text") }
  end

  x.compare!
end
```

## Compilation Optimizations

The Rust extension is compiled with aggressive optimizations:

```toml
[profile.release]
lto = true           # Link-time optimization
codegen-units = 1    # Single codegen unit for better optimization
```

These settings increase compile time but improve runtime performance by ~15-20%.

## Platform-Specific Notes

### macOS (Apple Silicon)
- Best performance on M1/M2/M3 chips
- Native ARM64 compilation
- ~10-15% faster than Intel Macs

### Linux
- Consistent performance across distributions
- Ensure Rust toolchain is up-to-date
- Consider using `jemalloc` for better memory allocation

### Windows
- Slightly slower file I/O may affect benchmarks
- Use native Windows paths for PathHierarchy tokenizer

## Troubleshooting Performance Issues

### Slow Tokenization

1. **Check pattern complexity**:
   ```ruby
   puts TokenKit.config.preserve_patterns
   ```

2. **Verify caching is working**:
   ```ruby
   # This should be fast after first call
   1000.times { TokenKit.tokenize("test") }
   ```

3. **Profile your patterns**:
   ```ruby
   require 'benchmark'

   patterns = [/pattern1/, /pattern2/, ...]
   text = "your text"

   patterns.each do |pattern|
     time = Benchmark.realtime do
       1000.times { pattern.match(text) }
     end
     puts "#{pattern}: #{time}s"
   end
   ```

### High Memory Usage

1. **Reduce n-gram sizes**:
   ```ruby
   config.max_gram = 5  # Instead of 10
   ```

2. **Limit preserve patterns**:
   ```ruby
   # Only essential patterns
   config.preserve_patterns = [/critical_pattern/]
   ```

3. **Use streaming for large documents**:
   ```ruby
   # Process in chunks
   text.each_line do |line|
     tokens = TokenKit.tokenize(line)
     process_tokens(tokens)
   end
   ```

## Future Optimizations

Planned performance improvements:

1. **SIMD vectorization** for character scanning
2. **Parallel tokenization** for very large texts
3. **Lazy pattern compilation** for rarely-used patterns
4. **Memory pooling** for reduced allocations
5. **Regex set optimization** for multiple patterns

## Summary

TokenKit achieves high performance through:

- **Intelligent caching**: 110x speedup for pattern-heavy workloads
- **Minimal allocations**: 20-30% throughput improvement
- **Optimized algorithms**: Using efficient Rust implementations
- **Smart defaults**: Unicode tokenizer balances speed and correctness

For most use cases, the default Unicode tokenizer with minimal preserve patterns provides the best performance. Configure once at application startup and let TokenKit's caching handle the rest.