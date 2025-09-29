#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "tokenkit"
require "benchmark/ips"

SAMPLE_TEXT = "The quick brown fox jumps over the lazy dog. Test email@example.com and URL https://example.com"

puts "Testing tokenizer caching optimization"
puts "=" * 50

# Test with preserve patterns (where caching helps most)
TokenKit.configure do |config|
  config.strategy = :unicode
  config.preserve_patterns = [
    /\w+@\w+\.\w+/,               # Email pattern
    /https?:\/\/[^\s]+/,          # URL pattern
    /\b[A-Z]{2,}\b/,              # Uppercase abbreviations
    /\b\d{4}-\d{2}-\d{2}\b/       # Date pattern
  ]
end

puts "\nWith preserve patterns (4 compiled regexes):"
Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)

  x.report("Cached tokenizer") do
    TokenKit.tokenize(SAMPLE_TEXT)
  end

  x.compare!
end

# Test without preserve patterns
TokenKit.reset
TokenKit.configure do |config|
  config.strategy = :unicode
end

puts "\nWithout preserve patterns:"
Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)

  x.report("Cached tokenizer") do
    TokenKit.tokenize(SAMPLE_TEXT)
  end

  x.compare!
end

# Test configuration changes (cache invalidation)
puts "\nConfiguration changes (worst case):"
Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)

  x.report("Reconfigure each time") do
    TokenKit.configure { |c| c.strategy = :unicode }
    TokenKit.tokenize(SAMPLE_TEXT)
  end

  x.compare!
end