require "rspec"

$LOAD_PATH << File.expand_path("../lib", __dir__)

support_glob = File.join(__dir__, "support", "**", "*.rb")
Dir[support_glob].sort.each { |f| require f }

require "simplecov"

SimpleCov.command_name "RSpec tests"

require "imap/backup"
require "imap/backup/cli"

silence_logging
