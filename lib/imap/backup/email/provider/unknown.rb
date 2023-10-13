require "imap/backup/email/provider/base"

module Imap; end

module Imap::Backup
  class Email::Provider::Unknown < Email::Provider::Base
    # We don't know how to guess the IMAP server
    def host
    end

    def options
      # rubocop:disable Naming/VariableNumber
      {port: 993, ssl: {ssl_version: :TLSv1_2}}
      # rubocop:enable Naming/VariableNumber
    end
  end
end
