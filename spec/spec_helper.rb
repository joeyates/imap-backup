require 'rspec'

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

require File.expand_path(File.dirname(__FILE__) + '/../lib/imap/backup')

module HighLineTestHelpers
  def prepare_highline
    @input = double('stdin', :eof? => false, :gets => "q\n")
    @output = StringIO.new
    Imap::Backup::Configuration::Setup.highline = HighLine.new(@input, @output)
    [@input, @output]
  end
end

module InputOutputTestHelpers
  def capturing_output
    output = StringIO.new
    $stdout = output
    yield
    output.string
  ensure
    $stdout = STDOUT
  end
end
