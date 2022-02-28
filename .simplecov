SimpleCov.coverage_dir(File.join(__dir__, "coverage"))

SimpleCov.start do
  add_filter "/spec/"
end

SimpleCov.at_exit do
  File.open(File.join(SimpleCov.coverage_path, "coverage_percent.txt"), "w") do |f|
    f.write SimpleCov.result.covered_percent
  end
  SimpleCov.result.format!
end
