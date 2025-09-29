# frozen_string_literal: true

RSpec.describe "Thread Safety" do
  after { TokenKit.reset }

  describe "concurrent tokenization" do
    it "handles multiple threads tokenizing simultaneously" do
      results = []
      threads = []

      10.times do |i|
        threads << Thread.new do
          text = "thread #{i} text"
          result = TokenKit.tokenize(text)
          results << result
        end
      end

      threads.each(&:join)

      expect(results.size).to eq(10)
      results.each do |result|
        expect(result).to be_a(Array)
        expect(result.size).to be >= 2
      end
    end

    it "handles concurrent configuration and tokenization" do
      errors = []
      results = []
      mutex = Mutex.new

      threads = []

      # Some threads configure
      5.times do |i|
        threads << Thread.new do
          begin
            TokenKit.configure do |config|
              config.strategy = [:whitespace, :unicode, :letter].sample
              config.lowercase = [true, false].sample
            end

            result = TokenKit.tokenize("Test TEXT #{i}")
            mutex.synchronize { results << result }
          rescue => e
            mutex.synchronize { errors << e }
          end
        end
      end

      # Some threads just tokenize
      5.times do |i|
        threads << Thread.new do
          begin
            result = TokenKit.tokenize("Test TEXT #{i}")
            mutex.synchronize { results << result }
          rescue => e
            mutex.synchronize { errors << e }
          end
        end
      end

      threads.each(&:join)

      expect(errors).to be_empty
      expect(results.size).to eq(10)
    end

    it "maintains configuration as global defaults (Phase 3 complete)" do
      # After Phase 3: configure sets global defaults,
      # but each tokenize call creates its own instance

      config_values = []
      tokenize_results = []
      mutex = Mutex.new

      threads = []
      2.times do |i|
        threads << Thread.new do
          strategy = i == 0 ? :whitespace : :unicode

          TokenKit.configure do |config|
            config.strategy = strategy
          end

          # Small delay to simulate race condition
          sleep(0.01)

          mutex.synchronize do
            config_values << TokenKit.config.strategy
            # Each tokenize creates a fresh instance
            tokenize_results << TokenKit.tokenize("hello-world")
          end
        end
      end

      threads.each(&:join)

      # Global config is shared (last writer wins)
      expect(config_values.size).to eq(2)
      # But tokenization still works correctly
      expect(tokenize_results.size).to eq(2)
      # Results depend on which config was active when tokenize was called
      expect(tokenize_results.flatten.uniq).to include("hello")
    end
  end

  describe "per-call options thread safety" do
    it "handles concurrent per-call tokenization" do
      results = []
      mutex = Mutex.new

      threads = []

      10.times do |i|
        threads << Thread.new do
          options = {
            strategy: [:whitespace, :unicode, :letter].sample,
            lowercase: [true, false].sample
          }

          result = TokenKit.tokenize("Test TEXT #{i}", **options)
          mutex.synchronize { results << result }
        end
      end

      threads.each(&:join)

      expect(results.size).to eq(10)
      results.each { |r| expect(r).to be_a(Array) }
    end
  end

  describe "stress testing" do
    it "handles rapid configuration changes" do
      errors = []

      thread = Thread.new do
        100.times do
          begin
            TokenKit.configure do |config|
              config.strategy = [:whitespace, :unicode, :letter].sample
              config.lowercase = [true, false].sample
            end
          rescue => e
            errors << e
          end
        end
      end

      thread.join
      expect(errors).to be_empty
    end

    it "handles concurrent reset and configure" do
      errors = []
      threads = []

      5.times do
        threads << Thread.new do
          begin
            TokenKit.reset
            TokenKit.configure do |config|
              config.strategy = :unicode
            end
            TokenKit.tokenize("test")
          rescue => e
            errors << e
          end
        end
      end

      threads.each(&:join)
      expect(errors).to be_empty
    end
  end

  describe "fresh instance behavior" do
    it "creates a fresh tokenizer for each call" do
      # Each tokenize call should be independent
      results = []
      threads = []

      TokenKit.configure do |c|
        c.strategy = :unicode
        c.lowercase = true
      end

      10.times do |i|
        threads << Thread.new do
          # Each should get its own tokenizer instance internally
          result = TokenKit.tokenize("Hello World")
          results << result
        end
      end

      threads.each(&:join)

      # All results should be the same (using same config)
      expect(results.size).to eq(10)
      expect(results.uniq.size).to eq(1)
      expect(results.first).to eq(["hello", "world"])
    end

    it "doesn't block other tokenize calls" do
      # Verify that multiple tokenize calls can run concurrently
      start_times = []
      end_times = []
      mutex = Mutex.new

      threads = 5.times.map do |i|
        Thread.new do
          mutex.synchronize { start_times << Time.now }
          TokenKit.tokenize("This is test text number #{i}")
          mutex.synchronize { end_times << Time.now }
        end
      end

      threads.each(&:join)

      # Check that threads overlapped
      earliest_end = end_times.min
      latest_start = start_times.max

      # Some threads should have started before others ended
      expect(latest_start).to be < (earliest_end + 0.01)
    end

    it "handles configuration changes safely during tokenization" do
      results = []
      mutex = Mutex.new
      threads = []

      # Some threads change config
      5.times do |i|
        threads << Thread.new do
          TokenKit.configure do |c|
            c.strategy = i.even? ? :whitespace : :unicode
          end
          sleep(0.001)
        end
      end

      # Other threads tokenize
      10.times do
        threads << Thread.new do
          sleep(0.001)
          result = TokenKit.tokenize("hello-world")
          mutex.synchronize { results << result }
        end
      end

      threads.each(&:join)

      expect(results.size).to eq(10)
      expect(results.flatten).not_to be_empty
    end
  end

  describe "performance" do
    it "handles high concurrency efficiently" do
      require 'benchmark'

      time = Benchmark.realtime do
        threads = 100.times.map do |i|
          Thread.new do
            10.times do
              TokenKit.tokenize("Test text #{i}")
            end
          end
        end
        threads.each(&:join)
      end

      # Should complete 1000 tokenizations quickly
      expect(time).to be < 1.0
    end
  end

  describe "memory safety" do
    it "does not leak memory with repeated configuration" do
      # This is a basic smoke test - proper memory testing
      # would require external tools

      initial_memory = `ps -o rss= -p #{Process.pid}`.to_i

      1000.times do
        TokenKit.configure do |config|
          config.strategy = [:whitespace, :unicode].sample
          config.preserve_patterns = [/test/, /pattern/]
        end
        TokenKit.tokenize("test text with patterns")
      end

      final_memory = `ps -o rss= -p #{Process.pid}`.to_i
      memory_growth = final_memory - initial_memory

      # Allow some growth but not excessive (e.g., < 50MB)
      expect(memory_growth).to be < 50_000
    end
  end
end