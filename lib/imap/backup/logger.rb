require "logger"
require "singleton"

require "imap/backup/configuration/store"
require "imap/backup/sanitizer"

module Imap::Backup
  class Logger
    include Singleton

    def self.logger
      Logger.instance.logger
    end

    def self.setup_logging(config = Configuration::Store.new)
      logger.level =
        if config.debug?
          ::Logger::Severity::DEBUG
        else
          ::Logger::Severity::ERROR
        end
      Net::IMAP.debug = config.debug?
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
