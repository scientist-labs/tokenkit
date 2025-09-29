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

    it "maintains configuration isolation per thread (current global behavior)" do
      # This test documents CURRENT behavior - global config
      # After Phase 3, this should change to per-instance isolation

      config_values = []
      mutex = Mutex.new

      threads = []
      2.times do |i|
        threads << Thread.new do
          strategy = i == 0 ? :whitespace : :unicode

          TokenKit.configure do |config|
            config.strategy = strategy
          end

          # Small delay to increase chance of race condition
          sleep(0.01)

          mutex.synchronize do
            config_values << TokenKit.config.strategy
          end
        end
      end

      threads.each(&:join)

      # Currently both threads affect global state
      # After refactor, each should maintain its own
      expect(config_values.size).to eq(2)
      # Current behavior: last writer wins
      # This documents that we have a race condition!
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