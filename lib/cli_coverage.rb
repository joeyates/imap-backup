class CliCoverage
  def self.conditionally_activate
    return if !ENV.key?("COVERAGE")

    require "simplecov"

    # Collect coverage separately
    SimpleCov.command_name "#{ENV.fetch('COVERAGE')} #{ARGV.join(' ')} coverage"

    # Silence output
    SimpleCov.formatter = SimpleCov::Formatter::SimpleFormatter
    SimpleCov.print_error_status = false

    # Ensure SimpleCov doesn't filter out all out code
    project_root = File.expand_path("..", __dir__)
    SimpleCov.root project_root
  end
end
