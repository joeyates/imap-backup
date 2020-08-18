support_glob = File.expand_path("support/**/*.rb", __dir__)
Dir[support_glob].sort.each { |f| require f }
