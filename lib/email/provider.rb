module Email; end

class Email::Provider
  def self.for_address(address)
    case
    when address.end_with?("@gmail.com")
      new(:gmail)
    when address.end_with?("@fastmail.fm")
      new(:fastmail)
    else
      new(:default)
    end
  end

  attr_reader :provider

  def initialize(provider)
    @provider = provider
  end

  def options
    {port: 993, ssl: {ssl_version: :TLSv1_2}}
  end

  def host
    case provider
    when :gmail
      "imap.gmail.com"
    when :fastmail
      "mail.messagingengine.com"
    end
  end
end
