# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/extensiontask"

# rspec and standard are DEVELOPMENT-only deps. The cross-compile build container
# (rb-sys-dock, via scientist-labs/rust-gem-release) installs the runtime bundle
# only, so these requires would raise LoadError and abort `rake` before the native
# build task can run. Guard them so this Rakefile always loads; the spec/standard
# tasks simply aren't available in a build-only environment.
begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  desc "run specs (rspec unavailable in this environment)"
  task(:spec) { abort "rspec is a development dependency and is not installed here" }
end

begin
  require "standard/rake"
rescue LoadError
  # standard is dev-only; skip the lint task when it isn't installed.
end

GEMSPEC = Gem::Specification.load("tokenkit.gemspec")

Rake::ExtensionTask.new("tokenkit", GEMSPEC) do |ext|
  ext.lib_dir = "lib/tokenkit"
  # cross_compile + cross_platform make rake-compiler expose the
  # `native:<platform>` tasks that rb-sys-dock invokes for each precompiled leg.
  # Without these, the cross build fails with "Don't know how to build task".
  ext.cross_compile = true
  ext.cross_platform = %w[x86_64-linux aarch64-linux arm64-darwin]
end

task spec: :compile
task default: %i[clobber compile spec standard]
