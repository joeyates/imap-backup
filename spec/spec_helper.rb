require "codeclimate-test-reporter"
require 'rspec'

CodeClimate::TestReporter.start

spec_path = File.dirname(__FILE__)
$LOAD_PATH << File.expand_path('../lib', spec_path)

support_glob = File.join(spec_path, 'support', '**', '*.rb')
Dir[support_glob].each { |f| require f }

if RUBY_VERSION < '1.9'
  require 'rspec/autorun'
else
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec/'
    add_filter '/vendor/'
  end
end

require 'imap/backup'

silence_logging
