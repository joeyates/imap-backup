require "thor"

require "imap/backup/cli/helpers"
require "imap/backup/setup"

module Imap; end

module Imap::Backup
  class CLI < Thor; end

  class CLI::Setup < Thor
    include Thor::Actions
    include CLI::Helpers

    def initialize(options)
      super([])
      @options = options
    end

    no_commands do
      def run
        config = load_config(**options, require_exists: false)
        Setup.new(config: config).run
      end
    end

    private

    attr_reader :options
  end
end
