SimpleCov.coverage_dir(File.join(__dir__, "coverage"))

SimpleCov.start do
  add_filter "/spec/"
end
