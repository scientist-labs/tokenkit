# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "standard/rake"
require "rake/extensiontask"

spec = Gem::Specification.load("tokenkit.gemspec")

Rake::ExtensionTask.new("tokenkit", spec) do |ext|
  ext.lib_dir = "lib/tokenkit"
  ext.ext_dir = "ext/tokenkit"
  ext.cross_compile = true
end

task default: %i[compile spec standard]
