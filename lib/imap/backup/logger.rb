require "net/imap"
require "logger"
require "singleton"

require "imap/backup/text/sanitizer"

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
      verbose = copy.delete(:verbose) || []
      verbose_count = count(verbose)
      level =
        case
        when quiet
          ::Logger::Severity::UNKNOWN
        when verbose_count >= 2
          ::Logger::Severity::DEBUG
        else
          ::Logger::Severity::INFO
        end
      logger.level = level

      Net::IMAP.debug = (verbose_count >= 3)

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

    def self.count(verbose)
      verbose.reduce(1) { |acc, v| acc + (v ? 1 : -1) }
    end

    attr_reader :logger

    def initialize
      @logger = ::Logger.new($stdout)
      $stdout.sync = true
    end
  end
end
