module Email; end

class Email::Provider
  GMAIL_IMAP_SERVER = "imap.gmail.com"

  def self.for_address(address)
    case
    when address.end_with?("@fastmail.com")
      new(:fastmail)
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
      GMAIL_IMAP_SERVER
    when :fastmail
      "imap.fastmail.com"
    end
  end
end
