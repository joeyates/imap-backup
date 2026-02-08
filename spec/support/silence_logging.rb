require "logger"
require "net/imap"

require "imap/backup/logger"

# This function can be used in specs/examples do logging and alter the logger configuration
def stub_logger
  logger = instance_double(
    Logger,
    debug: nil,
    error: nil,
    info: nil,
    "level=": nil
  )
  allow(Imap::Backup::Logger).to receive(:logger) { logger }
  logger
end

# Pass the `:silence_logging` option to `RSpec.describe`
# for specs that do logging, but do not alter logging setup
RSpec.configure do |config|
  config.around(:each, :silence_logging) do |example|
    previous_logger_level = Imap::Backup::Logger.logger.level
    previous_net_imap_debug = Net::IMAP.debug
    Imap::Backup::Logger.logger.level = Logger::Severity::UNKNOWN
    Net::IMAP.debug = false
    example.run
    Imap::Backup::Logger.logger.level = previous_logger_level
    Net::IMAP.debug = previous_net_imap_debug
  end
end
