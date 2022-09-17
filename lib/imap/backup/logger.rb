require "logger"
require "singleton"

require "imap/backup/configuration"
require "imap/backup/sanitizer"

module Imap::Backup
  class Logger
    include Singleton

    def self.logger
      Logger.instance.logger
    end

    def self.setup_logging(options = {})
      level =
        case
        when options[:quiet]
          ::Logger::Severity::UNKNOWN
        when options[:verbose]
          ::Logger::Severity::DEBUG
        else
          ::Logger::Severity::INFO
        end
      logger.level = level
      debug = level == ::Logger::Severity::DEBUG
      Net::IMAP.debug = debug
    end

    def self.sanitize_stderr
      sanitizer = Sanitizer.new($stdout)
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
