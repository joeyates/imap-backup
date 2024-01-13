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

    def sets_seen_flags_on_fetch?
      false
    end
  end
end
