module Imap::Backup
  class CLI::Folders < Thor
    include Thor::Actions
    include CLI::Helpers

    attr_reader :account_names

    def initialize(options)
      super([])
      @account_names = (options[:accounts] || "").split(",")
    end

    no_commands do
      def run
        each_connection(account_names) do |connection|
          puts connection.username
          # TODO: Make folder_names private once this command
          # has been removed.
          folders = connection.folder_names
          if folders.nil?
            warn "Unable to list account folders"
            return false
          end
          folders.each { |f| puts "\t#{f}" }
        end
      end
    end
  end
end
