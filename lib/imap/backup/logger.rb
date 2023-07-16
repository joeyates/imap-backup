require "logger"
require "singleton"

require "imap/backup/configuration"
require "text/sanitizer"

module Imap; end

module Imap::Backup
  class Logger
    include Singleton

    def self.logger
      Logger.instance.logger
    end

    def self.setup_logging(options = {})
      copy = options.clone
      quiet = copy.delete(:quiet)
      verbose = copy.delete(:verbose)
      level =
        case
        when quiet
          ::Logger::Severity::UNKNOWN
        when verbose
          ::Logger::Severity::DEBUG
        else
          ::Logger::Severity::INFO
        end
      logger.level = level
      debug = level == ::Logger::Severity::DEBUG
      Net::IMAP.debug = debug

      copy
    end

    def self.sanitize_stderr
      sanitizer = Text::Sanitizer.new($stdout)
      previous_stderr = $stderr
      $stderr = sanitizer
      yield
    ensure
      sanitizer.flush
      $stderr = previous_stderr
    end

    attr_reader :logger

    def initialize
      @logger = ::Logger.new($stdout)
      $stdout.sync = true
    end
  end
end
