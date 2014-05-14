require 'rspec'
spec_path = File.dirname(__FILE__)
$LOAD_PATH << File.expand_path('../lib', spec_path)

support_glob = File.join(spec_path, 'support', '**', '*.rb')
Dir[support_glob].each { |f| require f }

if RUBY_VERSION < '1.9'
  require 'rspec/autorun'
else
  require 'simplecov'
  if defined?(GATHER_RSPEC_COVERAGE)
    SimpleCov.start do
      add_filter "/spec/"
      add_filter "/vendor/"
    end
  end
end

require 'imap/backup'
