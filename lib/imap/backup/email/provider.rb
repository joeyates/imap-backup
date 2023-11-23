require "imap/backup/email/provider/apple_mail"
require "imap/backup/email/provider/fastmail"
require "imap/backup/email/provider/gmail"
require "imap/backup/email/provider/purelymail"
require "imap/backup/email/provider/unknown"

module Imap; end

module Imap::Backup
  module Email; end

  # Provides a class factory for email account providers
  class Email::Provider
    # @param address [String] an email address
    # @return [Email::Provider::Fastmail, Email::Provider::GMail, Email::Provider::AppleMail,
    #   Email::Provider::Purelymail, Email::Provider::Unknown]
    #   an instance supplying default values for the email's account set up
    def self.for_address(address)
      # rubocop:disable Lint/DuplicateBranch
      case
      when address.end_with?("@fastmail.com")
        Email::Provider::Fastmail.new
      when address.end_with?("@fastmail.fm")
        Email::Provider::Fastmail.new
      when address.end_with?("@gmail.com")
        Email::Provider::GMail.new
      when address.end_with?("@icloud.com")
        Email::Provider::AppleMail.new
      when address.end_with?("@mac.com")
        Email::Provider::AppleMail.new
      when address.end_with?("@me.com")
        Email::Provider::AppleMail.new
      when address.end_with?("@purelymail.com")
        Email::Provider::Purelymail.new
      else
        Email::Provider::Unknown.new
      end
      # rubocop:enable Lint/DuplicateBranch
    end
  end
end
