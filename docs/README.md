# TokenKit Documentation

Welcome to the TokenKit documentation! This directory contains in-depth guides for developers and contributors.

## 📚 Documentation Index

### For Users

- **[README](../README.md)** - Getting started, usage examples, and API overview
- **[Performance Guide](PERFORMANCE.md)** - Benchmarks, optimization techniques, and best practices

### For Contributors

- **[Architecture Guide](ARCHITECTURE.md)** - Internal design, Ruby-Rust bridge, and implementation details
- **[Code of Conduct](../CODE_OF_CONDUCT.md)** - Community standards and expectations

### API Reference

- **[RubyDoc](https://rubydoc.info/gems/tokenkit)** - Complete API documentation (once published)
- Generate locally: `bundle exec yard doc` then open `doc/index.html`

## 🚀 Quick Links

### Getting Help

- [GitHub Issues](https://github.com/scientist-labs/tokenkit/issues) - Report bugs or request features
- [GitHub Discussions](https://github.com/scientist-labs/tokenkit/discussions) - Ask questions and share ideas

### Key Features

- **13 Tokenization Strategies** - From simple whitespace to complex n-grams
- **Pattern Preservation** - Maintain domain-specific terms during tokenization
- **110x Performance Improvement** - Optimized caching and memory management
- **Thread-Safe** - Designed for concurrent production use
- **Comprehensive Error Handling** - Clear, actionable error messages

### Performance Highlights

| Metric | Performance | Notes |
|--------|------------|-------|
| Basic Unicode | ~870K ops/sec | Baseline performance |
| With 4 Preserve Patterns | ~410K ops/sec | Was 3.6K before v0.3.0 |
| Memory Usage | ~500 bytes/op | Minimal overhead |
| Thread Safety | No degradation | Safe concurrent use |

## 📖 Reading Order

For new users:
1. [README](../README.md) - Start here
2. [Performance Guide](PERFORMANCE.md) - Understand performance characteristics

For contributors:
2. [Architecture Guide](ARCHITECTURE.md) - Understand the codebase
3. [Performance Guide](PERFORMANCE.md) - Optimization techniques

## 🔧 Development Commands

```bash
# Setup
bundle install
bundle exec rake compile

# Testing
bundle exec rspec                    # Run tests
COVERAGE=true bundle exec rspec      # With coverage report
bundle exec standardrb                # Ruby linting

# Documentation
bundle exec yard doc                 # Generate API docs
open doc/index.html                  # View API docs

# Benchmarking
ruby benchmarks/tokenizer_benchmark.rb       # Full benchmark suite
ruby benchmarks/cache_test.rb                # Cache performance
ruby benchmarks/final_comparison.rb          # Before/after comparison

# Building
gem build tokenkit.gemspec           # Build gem
gem install ./tokenkit-*.gem         # Install locally
```

## 📊 Test Coverage

Current coverage (v0.3.0):
- **Line Coverage**: 94.12%
- **Branch Coverage**: 87.8%
- **Total Tests**: 418

## 🏗️ Architecture Overview

```
TokenKit Architecture
├── Ruby Layer (lib/)
│   ├── Public API (TokenKit module)
│   ├── Configuration management
│   └── Instance tokenizers
├── Magnus Bridge (FFI)
│   └── Automatic type conversion
└── Rust Layer (ext/tokenkit/src/)
    ├── Tokenizer trait
    ├── 13 strategy implementations
    ├── Pattern preservation
    └── Error handling
```

## 📝 Version History

- **v0.3.0** (Unreleased) - Major performance improvements, proper error handling
- **v0.2.0** - Added 10 new tokenization strategies
- **v0.1.0** - Initial release with 3 core strategies

## 📄 License

TokenKit is released under the [MIT License](../LICENSE.txt).

---

*Last updated: 2025-09-29*
