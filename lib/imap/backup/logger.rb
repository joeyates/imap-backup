require "logger"
require "singleton"

require "imap/backup/configuration/store"

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

    attr_reader :logger

    def initialize
      @logger = ::Logger.new($stdout)
      $stdout.sync = true
    end
  end
end
