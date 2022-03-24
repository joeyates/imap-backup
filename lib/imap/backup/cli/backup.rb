module Imap::Backup
  class CLI::Backup < Thor
    include Thor::Actions
    include CLI::Helpers

    attr_reader :account_names

    def initialize(options)
      super([])
      @account_names = (options[:accounts] || "").split(",")
    end

    no_commands do
      def run
        each_connection(account_names, &:run_backup)
      end
    end
  end
end
