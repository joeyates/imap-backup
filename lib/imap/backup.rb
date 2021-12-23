module Imap; end

require "imap/backup/utils"
require "imap/backup/account/connection"
require "imap/backup/account/folder"
require "imap/backup/configuration/list"
require "imap/backup/configuration/store"
require "imap/backup/downloader"
require "imap/backup/logger"
require "imap/backup/uploader"
require "imap/backup/serializer"
require "imap/backup/serializer/mbox"
require "imap/backup/setup"
require "imap/backup/setup/account"
require "imap/backup/setup/asker"
require "imap/backup/setup/connection_tester"
require "imap/backup/setup/folder_chooser"
require "imap/backup/version"
require "email/provider"

module Imap::Backup
  class ConfigurationNotFound < StandardError; end
end
