module Imap; end

module Imap::Backup
  module Email; end
  class Email::Provider; end

  # Supplies defaults for email provider behaviour
  class Email::Provider::Base
    # @return [Hash] defaults for the Net::IMAP connection
    def options
      {port: 993, ssl: {min_version: OpenSSL::SSL::TLS1_2_VERSION}}
    end

    # By default, we query the server for this value.
    # It is only fixed for Apple Mail accounts.
    # @return [String, nil] any fixed value to use when requesting the list of account folders
    def root
    end

    def sets_seen_flags_on_fetch?
      false
    end
  end
end
