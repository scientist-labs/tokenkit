#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "tokenkit"
require "benchmark/ips"
require "benchmark/memory"

# Sample texts of various sizes
SMALL_TEXT = "The quick brown fox jumps over the lazy dog."
MEDIUM_TEXT = SMALL_TEXT * 10
LARGE_TEXT = File.read(File.join(__dir__, "../README.md")) * 5
UNICODE_TEXT = "Hello 世界 мир العالم! Testing 🔥 emoji and café résumé naïve."
PATTERN_TEXT = "Contact us at user@example.com or visit https://example.com. Code: ABC-123, Date: 2024-01-15."

puts "TokenKit Performance Benchmarks"
puts "=" * 50

def run_tokenizer_benchmarks
  puts "\n📊 Tokenizer Strategy Comparison (small text)"
  puts "-" * 40

  Benchmark.ips do |x|
    x.config(time: 5, warmup: 2)

    x.report("Unicode") do
      TokenKit.reset
      TokenKit.configure { |c| c.strategy = :unicode }
      TokenKit.tokenize(SMALL_TEXT)
    end

    x.report("Whitespace") do
      TokenKit.reset
      TokenKit.configure { |c| c.strategy = :whitespace }
      TokenKit.tokenize(SMALL_TEXT)
    end

    x.report("Letter") do
      TokenKit.reset
      TokenKit.configure { |c| c.strategy = :letter }
      TokenKit.tokenize(SMALL_TEXT)
    end

    x.report("Lowercase") do
      TokenKit.reset
      TokenKit.configure { |c| c.strategy = :lowercase }
      TokenKit.tokenize(SMALL_TEXT)
    end

    x.report("Pattern (email)") do
      TokenKit.reset
      TokenKit.configure do |c|
        c.strategy = :pattern
        c.regex = /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/
      end
      TokenKit.tokenize(PATTERN_TEXT)
    end

    x.report("EdgeNgram") do
      TokenKit.reset
      TokenKit.configure do |c|
        c.strategy = :edge_ngram
        c.min_gram = 2
        c.max_gram = 5
      end
      TokenKit.tokenize(SMALL_TEXT)
    end

    x.compare!
  end
end

def run_configuration_benchmarks
  puts "\n⚙️  Configuration Options Impact"
  puts "-" * 40

  Benchmark.ips do |x|
    x.config(time: 5, warmup: 2)

    x.report("Basic Unicode") do
      TokenKit.reset
      TokenKit.configure { |c| c.strategy = :unicode }
      TokenKit.tokenize(MEDIUM_TEXT)
    end

    x.report("Unicode + lowercase") do
      TokenKit.reset
      TokenKit.configure do |c|
        c.strategy = :unicode
        c.lowercase = true
      end
      TokenKit.tokenize(MEDIUM_TEXT)
    end

    x.report("Unicode + remove_punctuation") do
      TokenKit.reset
      TokenKit.configure do |c|
        c.strategy = :unicode
        c.remove_punctuation = true
      end
      TokenKit.tokenize(MEDIUM_TEXT)
    end

    x.report("Unicode + preserve_patterns") do
      TokenKit.reset
      TokenKit.configure do |c|
        c.strategy = :unicode
        c.preserve_patterns = [/\b[A-Z]{2,}\b/, /\d{4}-\d{2}-\d{2}/]
      end
      TokenKit.tokenize(MEDIUM_TEXT)
    end

    x.report("Unicode + all options") do
      TokenKit.reset
      TokenKit.configure do |c|
        c.strategy = :unicode
        c.lowercase = true
        c.remove_punctuation = true
        c.preserve_patterns = [/\b[A-Z]{2,}\b/, /\d{4}-\d{2}-\d{2}/]
      end
      TokenKit.tokenize(MEDIUM_TEXT)
    end

    x.compare!
  end
end

def run_text_size_benchmarks
  puts "\n📏 Text Size Scaling"
  puts "-" * 40

  TokenKit.configure { |c| c.strategy = :unicode }

  Benchmark.ips do |x|
    x.config(time: 5, warmup: 2)

    x.report("Small (#{SMALL_TEXT.length} chars)") do
      TokenKit.tokenize(SMALL_TEXT)
    end

    x.report("Medium (#{MEDIUM_TEXT.length} chars)") do
      TokenKit.tokenize(MEDIUM_TEXT)
    end

    x.report("Large (#{LARGE_TEXT.length} chars)") do
      TokenKit.tokenize(LARGE_TEXT)
    end

    x.compare!
  end
end

def run_instance_vs_module_benchmarks
  puts "\n🔄 Module vs Instance API"
  puts "-" * 40

  TokenKit.configure do |c|
    c.strategy = :unicode
    c.lowercase = true
  end

  tokenizer = TokenKit::Tokenizer.new(strategy: :unicode, lowercase: true)

  Benchmark.ips do |x|
    x.config(time: 5, warmup: 2)

    x.report("Module API (creates fresh instance)") do
      TokenKit.tokenize(MEDIUM_TEXT)
    end

    x.report("Instance API (reused instance)") do
      tokenizer.tokenize(MEDIUM_TEXT)
    end

    x.report("Per-call options") do
      TokenKit.tokenize(MEDIUM_TEXT, lowercase: false)
    end

    x.compare!
  end
end

def run_thread_safety_benchmarks
  puts "\n🧵 Thread Safety & Concurrency"
  puts "-" * 40

  TokenKit.configure { |c| c.strategy = :unicode }

  Benchmark.ips do |x|
    x.config(time: 5, warmup: 2)

    x.report("Single-threaded (10 tokenizations)") do
      10.times { TokenKit.tokenize(SMALL_TEXT) }
    end

    x.report("Multi-threaded (10 threads)") do
      threads = 10.times.map do
        Thread.new { TokenKit.tokenize(SMALL_TEXT) }
      end
      threads.each(&:join)
    end

    x.compare!
  end
end

def run_memory_benchmarks
  puts "\n💾 Memory Usage Analysis"
  puts "-" * 40

  Benchmark.memory do |x|
    x.report("Unicode tokenizer") do
      TokenKit.reset
      TokenKit.configure { |c| c.strategy = :unicode }
      100.times { TokenKit.tokenize(MEDIUM_TEXT) }
    end

    x.report("EdgeNgram tokenizer") do
      TokenKit.reset
      TokenKit.configure do |c|
        c.strategy = :edge_ngram
        c.min_gram = 2
        c.max_gram = 5
      end
      100.times { TokenKit.tokenize(MEDIUM_TEXT) }
    end

    x.report("With preserve_patterns") do
      TokenKit.reset
      TokenKit.configure do |c|
        c.strategy = :unicode
        c.preserve_patterns = [/\b[A-Z]{2,}\b/, /\d{4}-\d{2}-\d{2}/, /\w+@\w+\.\w+/]
      end
      100.times { TokenKit.tokenize(MEDIUM_TEXT) }
    end

    x.compare!
  end
end

# Run all benchmarks
run_tokenizer_benchmarks if ARGV.empty? || ARGV.include?("tokenizers")
run_configuration_benchmarks if ARGV.empty? || ARGV.include?("config")
run_text_size_benchmarks if ARGV.empty? || ARGV.include?("size")
run_instance_vs_module_benchmarks if ARGV.empty? || ARGV.include?("instance")
run_thread_safety_benchmarks if ARGV.empty? || ARGV.include?("threads")
run_memory_benchmarks if ARGV.empty? || ARGV.include?("memory")

puts "\n" + "=" * 50
puts "Benchmark complete!"