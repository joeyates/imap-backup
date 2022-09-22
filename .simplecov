SimpleCov.coverage_dir(File.join(__dir__, "coverage"))

SimpleCov.start do
  add_filter "/spec/"

  enable_coverage :branch
end

SimpleCov.at_exit do
  File.open(File.join(SimpleCov.coverage_path, "coverage_percent.txt"), "w") do |f|
    rounded = (SimpleCov.result.covered_percent + 0.5).floor
    f.write rounded
  end
  SimpleCov.result.format!
end
