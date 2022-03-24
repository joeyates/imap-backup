require "email/provider/apple_mail"
require "email/provider/fastmail"
require "email/provider/gmail"
require "email/provider/unknown"

module Email; end

class Email::Provider
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
    else
      Email::Provider::Unknown.new
    end
    # rubocop:enable Lint/DuplicateBranch
  end
end
