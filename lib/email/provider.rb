require "email/provider/default"
require "email/provider/fastmail"
require "email/provider/gmail"

module Email; end

class Email::Provider
  def self.for_address(address)
    case
    when address.end_with?("@fastmail.com")
      Email::Provider::Fastmail.new
    when address.end_with?("@fastmail.fm")
      Email::Provider::Fastmail.new
    when address.end_with?("@gmail.com")
      Email::Provider::GMail.new
    else
      Email::Provider::Default.new
    end
  end
end
