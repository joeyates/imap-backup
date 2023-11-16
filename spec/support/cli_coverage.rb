class CliCoverage
  def self.conditionally_activate
    return if !ENV.key?("COVERAGE")

    # Collect coverage separately
    ENV["SIMPLECOV_COMMAND_NAME"] = "#{ENV.fetch('COVERAGE')} #{ARGV.join(' ')} coverage"
    require "simplecov"

    # Silence output
    SimpleCov.formatter = SimpleCov::Formatter::SimpleFormatter
    SimpleCov.print_error_status = false
  end
end
