require "net/imap"
require "logger"
require "singleton"

require "imap/backup/text/sanitizer"

module Imap; end

module Imap::Backup
  # Wraps the standard logger, providing configuration and sanitization
  class Logger
    include Singleton

    # @return [Imap::Backup::Logger] the singleton instance of this class
    def self.logger
      Logger.instance.logger
    end

    # @param options [Hash] command-line options
    # @option options [Boolean] :quiet (false) if true, no output will be written
    # @option options [Array<Boolean>] :verbose ([]) counts how many `--verbose`
    #   parameters were passed (and, potentially subtracts the number of
    #   `--no-verbose` parameters).
    #   If the result is 0, does normal info-level logging,
    #   If the result is 1, does debug logging,
    #   If the result is 2, does debug logging and client-server debug logging.
    #   This option is overridden by the `:verbose` option.
    #
    # @return [Hash] the options without the :quiet and :verbose keys
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

    # Wraps a block, filtering output to standard error,
    # hidng passwords and outputs the results to standard out
    # @return [void]
    def self.sanitize_stderr(&block)
      sanitizer = Text::Sanitizer.new($stdout)
      previous_stderr = $stderr
      $stderr = sanitizer
      block.call
    ensure
      sanitizer.flush
      $stderr = previous_stderr
    end

    # @private
    def self.count(verbose)
      verbose.reduce(1) { |acc, v| acc + (v ? 1 : -1) }
    end

    # @return [Logger] the configured Logger
    attr_reader :logger

    def initialize
      @logger = ::Logger.new($stdout)
      $stdout.sync = true
    end
  end
end
