module Imap; end

module Imap::Backup
  class CLI::Setup < Thor
    include Thor::Actions
    include CLI::Helpers

    attr_reader :options

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
  end
end
