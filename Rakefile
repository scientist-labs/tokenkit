# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "standard/rake"

task :compile do
  Dir.chdir("ext/tokenkit") do
    ruby "extconf.rb"
    sh "make"
  end

  FileUtils.mkdir_p "lib/tokenkit"
  FileUtils.cp "ext/tokenkit/tokenkit.bundle", "lib/tokenkit/tokenkit.bundle"
end

task :clean do
  sh "rm -f ext/tokenkit/Makefile"
  sh "rm -f ext/tokenkit/tokenkit.bundle"
  sh "rm -rf ext/tokenkit/tokenkit.bundle.dSYM"
  sh "rm -rf lib/tokenkit/tokenkit.bundle"
  sh "rm -rf target"
  sh "rm -rf ext/tokenkit/target"
end

task spec: :compile
task default: %i[compile spec standard]