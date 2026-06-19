# frozen_string_literal: true

require_relative "lib/tokenkit/version"

Gem::Specification.new do |spec|
  spec.name = "tokenkit"
  spec.version = TokenKit::VERSION
  spec.authors = ["Chris Petersen"]
  spec.email = ["chris@petersen.io"]

  spec.summary = "Fast, Rust-backed word-level tokenization for Ruby"
  spec.description = "TokenKit provides lightweight, Unicode-aware word-level tokenization with pattern preservation, backed by Rust for performance."
  spec.homepage = "https://github.com/scientist-labs/tokenkit"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/scientist-labs/tokenkit"

  # Indicate that Rust toolchain is required to build this gem
  spec.requirements = ["Rust >= 1.85"]

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile]) ||
        f.match?(/TOKENKIT-PROPOSAL\.md/)
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Precompiled platform gems (e.g. arm64-darwin, built natively on a macOS runner)
  # carry one compiled extension per Ruby ABI under lib/tokenkit/<major.minor>/ and must
  # NOT declare extensions, or RubyGems would try to recompile from Rust source on
  # install — defeating the precompiled gem. The linux platform gems are assembled by
  # rake-compiler/rb_sys (which clears extensions itself); this env gate covers the
  # manually-assembled darwin fat gem. The freshly-compiled bundles are untracked, so the
  # `spec.files +=` append is required (spec.files above comes from `git ls-files`).
  # Unset => normal source gem.
  if (platform_gem = ENV["RUST_GEM_PLATFORM"])
    spec.platform = platform_gem
    spec.extensions = []
    spec.files += Dir["lib/tokenkit/*/tokenkit.bundle"] + Dir["lib/tokenkit/*/tokenkit.so"]
  else
    spec.extensions = ["ext/tokenkit/extconf.rb"]
  end

  spec.add_dependency "rb_sys", "~> 0.9"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rake-compiler", "~> 1.2"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "standard", "~> 1.3"
  spec.add_development_dependency "simplecov", "~> 0.22"
end
