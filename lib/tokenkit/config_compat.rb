# frozen_string_literal: true

module TokenKit
  # Compatibility wrapper that mimics the old Config singleton API
  # This allows us to migrate gradually
  class Config
    # Singleton pattern for backward compatibility
    def self.instance
      @instance ||= new
    end

    # Delegate all accessors to the global config builder
    def method_missing(method, *args, &block)
      if method.to_s.end_with?('=')
        # Setter - store in temporary builder
        attr = method.to_s.chomp('=').to_sym
        @temp_builder ||= TokenKit.config_hash.to_builder
        @temp_builder.send(method, *args, &block) if @temp_builder.respond_to?(method)
      else
        # Getter - get from current config or temp builder
        if @temp_builder && @temp_builder.respond_to?(method)
          @temp_builder.send(method)
        else
          TokenKit.config_hash.send(method) if TokenKit.config_hash.respond_to?(method)
        end
      end
    end

    def respond_to_missing?(method, include_private = false)
      # Avoid infinite recursion by checking config_hash instead of config
      return true if [:strategy=, :lowercase=, :remove_punctuation=, :preserve_patterns=,
                      :regex=, :grapheme_extended=, :min_gram=, :max_gram=,
                      :delimiter=, :split_on_chars=,
                      :strategy, :lowercase, :remove_punctuation, :preserve_patterns,
                      :regex, :grapheme_extended, :min_gram, :max_gram,
                      :delimiter, :split_on_chars].include?(method)
      super
    end

    # Called by TokenKit.configure to get the built config
    def build_config
      builder = @temp_builder || TokenKit.config_hash.to_builder
      @temp_builder = nil  # Clear after building
      builder
    end

    # Reset temporary builder
    def reset_temp
      @temp_builder = nil
    end
  end
end