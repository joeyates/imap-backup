require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

desc "Run all specs"
RSpec::Core::RakeTask.new do |t|
  t.pattern = "spec/**/*_spec.rb"
end

desc "Run unit specs"
RSpec::Core::RakeTask.new(:spec_unit) do |task|
  task.pattern = "spec/unit/**/*_spec.rb"
end

desc "Run feature specs"
RSpec::Core::RakeTask.new(:spec_feature) do |task|
  task.pattern = "spec/feature/**/*_spec.rb"
end

desc "Run non-container specs"
RSpec::Core::RakeTask.new(:spec_non_container) do |task|
  task.rspec_opts = "--tag ~container"
end

RuboCop::RakeTask.new(:rubocop) do |task|
  task.options = ["--config", ".rubocop.yml"]
end

task :test => [:spec, :rubocop]
