# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "standard/rake"
require "rake/extensiontask"

GEMSPEC = Gem::Specification.load("tokenkit.gemspec")

Rake::ExtensionTask.new("tokenkit", GEMSPEC) do |ext|
  ext.lib_dir = "lib/tokenkit"
end

task spec: :compile
task default: %i[clobber compile spec standard]
