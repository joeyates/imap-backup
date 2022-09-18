module Imap::Backup
  class CLI::Restore < Thor
    include Thor::Actions
    include CLI::Helpers

    attr_reader :email
    attr_reader :emails

    def initialize(email = nil, options)
      super([])
      @email = email
      @emails = options[:accounts].split(",") if options.key?(:accounts)
    end

    no_commands do
      def run
        config = load_config
        case
        when email && !emails
          connection = connection(config, email)
          connection.restore
        when !email && !emails
          Logger.logger.info "Calling restore without an EMAIL parameter is deprecated"
          each_connection(config, [], &:restore)
        when email && emails.any?
          raise "Pass either an email or the --accounts option, not both"
        when emails.any?
          Logger.logger.info(
            "Calling restore with the --account option is deprected, " \
            "please pass a single EMAIL argument"
          )
          each_connection(config, emails, &:restore)
        end
      end
    end
  end
end
