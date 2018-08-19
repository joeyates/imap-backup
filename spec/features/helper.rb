support_glob = File.expand_path("support/**/*.rb", __dir__)
Dir[support_glob].each { |f| require f }
