class CliCoverage
  def self.conditionally_activate
    return if !ENV.key?("FEATURE_SPEC_ID")

    # Collect coverage separately
    ENV["SIMPLECOV_COMMAND_NAME"] = ENV.fetch("FEATURE_SPEC_ID")
    require "simplecov"

    # Silence output
    SimpleCov.formatter = SimpleCov::Formatter::SimpleFormatter
    SimpleCov.print_error_status = false
  end
end
