module Imap::Backup
  class CLI::Setup < Thor
    include Thor::Actions

    def initialize
      super([])
    end

    no_commands do
      def run
        Setup.new.run
      end
    end
  end
end
