require "imap/backup/logger"

def silence_logging
  RSpec.configure do |config|
    config.before do
      Imap::Backup::Logger.logger.level = Logger::UNKNOWN
      Net::IMAP.debug = false
    end
  end
end
