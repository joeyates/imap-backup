module Imap; end

require "imap/backup/utils"
require "imap/backup/account/connection"
require "imap/backup/account/folder"
require "imap/backup/configuration/account"
require "imap/backup/configuration/asker"
require "imap/backup/configuration/connection_tester"
require "imap/backup/configuration/folder_chooser"
require "imap/backup/configuration/list"
require "imap/backup/configuration/setup"
require "imap/backup/configuration/store"
require "imap/backup/downloader"
require "imap/backup/uploader"
require "imap/backup/serializer"
require "imap/backup/serializer/mbox"
require "imap/backup/version"
require "email/provider"

require "logger"

module Imap::Backup
  class ConfigurationNotFound < StandardError; end

  class Logger
    include Singleton

    attr_reader :logger

    def initialize
      @logger = ::Logger.new(STDOUT)
    end
  end

  def self.logger
    Logger.instance.logger
  end

  def self.setup_logging(config)
    logger.level =
      if config.debug?
        ::Logger::Severity::DEBUG
      else
        ::Logger::Severity::ERROR
      end
  end
end
