module Imap::Backup
  class CLI::Restore < Thor
    include Thor::Actions
    include CLI::Helpers

    attr_reader :email
    attr_reader :account_names

    def initialize(email = nil, options)
      @email = email
      @account_names =
        if options.key?(:accounts)
          options[:accounts].split(",")
        end
    end

    no_commands do
      def run
        case
        when email && !account_names
          connection = connection(email)
          connection.restore
        when !email && !account_names
          Logger.logger.info "Calling restore without an EMAIL parameter is deprecated"
          each_connection([]) { |connection| connection.restore }
        when email && account_names.any?
          raise "Pass either an email or the --accounts option, not both"
        when account_names.any?
          Logger.logger.info "Calling restore with the --account option is deprected, please pass a single EMAIL argument"
          each_connection(account_names) { |connection| connection.restore }
        end
      end
    end
  end
end
