# If the environment variable 'PERFORMANCE' is set,
# run *only* performance specs.
# Otherwise, run other specs, skipping performace ones.
RSpec.configure do |config|
  performance_run = !!ENV["PERFORMANCE"]
  config.filter_run_excluding performance: !performance_run
  config.filter_run_when_matching performance: performance_run
end

Aruba.configure do |config|
  config.exit_timeout = 6 * 60 * 60 if !!ENV["PERFORMANCE"]
end
