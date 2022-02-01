require "aruba/rspec"

Aruba.configure do |config|
  config.home_directory = File.expand_path("./tmp/home")
end
