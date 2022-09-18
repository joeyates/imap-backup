module Imap::Backup
  class CLI::Folders < Thor
    include Thor::Actions
    include CLI::Helpers

    attr_reader :emails

    def initialize(options)
      super([])
      @emails = (options[:accounts] || "").split(",")
    end

    no_commands do
      def run
        each_connection(emails) do |connection|
          Kernel.puts connection.account.username
          # TODO: Make folder_names private once this command
          # has been removed.
          folders = connection.folder_names
          if folders.nil?
            Kernel.warn "Unable to list account folders"
            return false
          end
          folders.each { |f| Kernel.puts "\t#{f}" }
        end
      end
    end
  end
end
