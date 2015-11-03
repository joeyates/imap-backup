require "codeclimate-test-reporter"
require 'rspec'

CodeClimate::TestReporter.start

spec_path = File.dirname(__FILE__)
$LOAD_PATH << File.expand_path('../lib', spec_path)

support_glob = File.join(spec_path, 'support', '**', '*.rb')
Dir[support_glob].each { |f| require f }

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

require 'imap/backup'

silence_logging
