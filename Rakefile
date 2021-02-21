require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new do |t|
  t.pattern = "spec/**/*_spec.rb"
end

desc "Run RSpec examples, excluding ones relying on Docker IMAP"
RSpec::Core::RakeTask.new("no-docker") do |t|
  t.pattern = "spec/**/*_spec.rb"
  t.rspec_opts = "--tag ~docker"
end

RuboCop::RakeTask.new

task default: :spec
task default: :rubocop
