def silence_logging
  RSpec.configure do |config|
    config.before(:suite) do
      Imap::Backup.logger.level = Logger::UNKNOWN
    end
  end
end
