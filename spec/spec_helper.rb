require 'rspec'

if RUBY_VERSION < '1.9'
  require 'rspec/autorun'
else
  require 'simplecov'
  if defined?( GATHER_RSPEC_COVERAGE )
    SimpleCov.start do
      add_filter "/spec/"
      add_filter "/vendor/"
    end
  end
end

require File.expand_path( File.dirname(__FILE__) + '/../lib/imap/backup' )

