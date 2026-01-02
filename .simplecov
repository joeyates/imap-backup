require "simplecov_json_formatter"

SimpleCov.start do
  command_name ENV.fetch("SIMPLECOV_COMMAND_NAME")

  # Ensure SimpleCov doesn't filter out all out code
  root __dir__

  add_filter "/spec/"

  enable_coverage :branch

  if ENV['CI']
    formatter SimpleCov::Formatter::SimpleFormatter
  else
    formatter SimpleCov::Formatter::MultiFormatter.new([
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::JSONFormatter
    ])
  end
end

SimpleCov.at_exit do
  File.open(File.join(SimpleCov.coverage_path, "coverage_percent.txt"), "w") do |f|
    rounded = (SimpleCov.result.covered_percent + 0.5).floor
    f.write rounded
  end
  SimpleCov.result.format!
end
