SimpleCov.start do
  command_name ENV.fetch("SIMPLECOV_COMMAND_NAME")

  # Ensure SimpleCov doesn't filter out all out code
  root __dir__

  add_filter "/spec/"

  coverage_dir(File.join(__dir__, "coverage"))

  enable_coverage :branch
end

SimpleCov.at_exit do
  File.open(File.join(SimpleCov.coverage_path, "coverage_percent.txt"), "w") do |f|
    rounded = (SimpleCov.result.covered_percent + 0.5).floor
    f.write rounded
  end
  SimpleCov.result.format!
end
